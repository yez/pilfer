require 'zip'
class Pilferer
  include HTTParty

  THREAD_POOL = 10

  def initialize(url)
    parsed = URI.parse(url)
    @base_url = "#{parsed.scheme + "://" if parsed.scheme}#{parsed.host}"
    @full_url = parsed.to_s
  end

  def scrape_all(threaded = true)
    images = get_images.flatten.uniq

    if threaded
      images_queue = Queue.new
      images.each { |img| images_queue << img }
      download_images(images_queue)
    else
      images.each { |image| download_image(image)}
    end

    zip_files

    delete_files

    archive_file_name
  end

  def get_images
    images_from_result(get_page(@full_url))
  end

  def get_page(url)
    Nokogiri::HTML::Document.parse(self.class.get(url))
  end

  def images_from_result(nokogiri_result)
    [].tap do |images|
      images << sources(nokogiri_result.css('img'))
      images << iframe_images(nokogiri_result)
    end
  end

  def iframe_images(nokogiri_result)
    [].tap do |arr|
      nokogiri_result.css('iframe').each do |iframe|
        url = iframe.attributes.select { |name, value| name == 'src' }["src"].value
        iframe_pilferer = Pilferer.new(url)
        arr << iframe_pilferer.get_images
      end
    end
  end

  def sources(images)
    [].tap do |arr|
      images.each do |image|
        image.attributes.each do |name, attribute|
          if name == 'src'
            parsed_src = URI.parse(attribute.value)
            arr << begin
              if parsed_src.scheme.nil? && parsed_src.host.nil?
                if attribute.value[0] == "/"
                  "#{@base_url}#{attribute.value}"
                else
                  "#{@base_url}/#{attribute.value}"
                end
              else
                parsed_src.to_s
              end
            end
          end
        end
      end
    end
  end

  def local_files
    @local_files ||= Queue.new
  end

  def download_images(images)
    threads = []
    THREAD_POOL.times do
      threads << Thread.new do
        while ( images.length > 0 && url = images.pop ) do
          download_image(url)
        end
      end
    end

    threads.map(&:join)
  end

  def image_name(url)
    url.split('/').last.split('.').first.gsub(/\?.*/, '')
  end

  def download_image(image_url)
    name = image_name(image_url)
    end_of_url_array = name.split('.')
    image_extension = (end_of_url_array.count == 1) ? "jpg" : end_of_url_array.last.gsub(/\?.*/, '')
    new_image_name = "#{name[0..30]}.#{image_extension}"
    file_name = "/tmp/#{UUID.generate(:compact)[0..5]}_#{new_image_name}"
    local_files << file_name
    File.open(file_name, 'wb') do |f|
      begin
        image_data = self.class.get(image_url)
        f.puts(image_data)
      rescue Exception => e
        Rails.logger.info("whoops: #{e}")
      end
    end
  end

  def delete_files
    files_to_delete.each do |f|
      File.delete(f)
    end
  end

  def zip_files
    Zip::File.open(archive_file_name, Zip::File::CREATE) do |zipfile|
      while ( local_files.length > 0 && full_filename = local_files.pop ) do
        short_name = full_filename.split('/').last
        zipfile.add(short_name, full_filename)
        files_to_delete << full_filename
      end
    end
  end

  def archive_file_name
    "/tmp/archive.zip"
  end

  def files_to_delete
    @files_to_delete ||= []
  end
end
