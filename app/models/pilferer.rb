require 'zip'
class Pilferer

  include HTTParty

  attr_accessor :base_url, :full_url

  THREAD_POOL       = 10
  MINIMUM_FILE_SIZE = 1000

  def initialize(url)
    nice_url = NiceUrl.new(url)
    if nice_url.valid?
      self.base_url = nice_url.base_url
      self.full_url = nice_url.full_url
    end
  end

  def scrape_all(threaded = true)
    images = get_images

    time_taken = Benchmark.measure do
      if threaded
        images_queue = Queue.new
        images.each { |img| images_queue << img }
        download_images(images_queue)
      else
        images.each { |image| download_image(image)}
      end
    end

    puts "downloading: #{time_taken}"

    time_taken = Benchmark.measure do
      zip_files
    end

    puts "zipping: #{time_taken}"

    time_taken = Benchmark.measure do
      delete_files
    end

    puts "deleting: #{time_taken}"

    archive_file_name
  end

  def get_images
    images_from_result(get_page(self.full_url))
  end

  def valid_url?
    self.base_url.present? && self.full_url.present?
  end

private

  def get_page(url)
    page = nil
    begin
      page = self.class.get(url)
    rescue Exception => e
      Rails.logger.debug("whoops #{e}")
    end
    Nokogiri::HTML::Document.parse(page)
  end

  def images_from_result(nokogiri_result)
    [].tap do |images|
      nokogiri_result.css('img').each do |noko_data|
        image = Image.new(noko_data, base_url)
        images << image if image.source.present?
      end

      iframe_images(nokogiri_result).each do |iframe_image|
        images << iframe_image
      end
    end
  end

  def iframe_images(nokogiri_result)
    iframe_found_images = Queue.new
    threads = []
    nokogiri_result.css('iframe').each do |iframe|
      sources = iframe.attributes.select { |name, value| name == 'src' }
      sources_queue = Queue.new
      sources.each do |source|
        sources_queue << source
      end

      THREAD_POOL.times do
        threads << Thread.new do
          while ( sources_queue.length > 0 && source = sources_queue.pop ) do
            iframe_pilferer = Pilferer.new(source.last.value)
            if iframe_pilferer.valid_url?
              iframe_found_images << iframe_pilferer.get_images
            end
          end
        end
      end
    end

    threads.map(&:join)

    return_images = []
    while(iframe_found_images.length > 0 && image_set = iframe_found_images.pop) do
      return_images << image_set
    end

    return_images.flatten
  end

  def local_files
    @local_files ||= Queue.new
  end

  def download_images(images)
    threads = []
    THREAD_POOL.times do
      threads << Thread.new do
        while ( images.length > 0 && image = images.pop ) do
          download_image(image)
        end
      end
    end

    threads.map(&:join)
  end

  def download_image(image)
    local_files << image.local_file_name
    File.open(image.local_file_name, 'wb') do |f|
      begin
        image_data = image.download
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
    Zip::File.open("#{archive_file_path}/#{archive_file_name}", Zip::File::CREATE) do |zipfile|
      while ( local_files.length > 0 && full_filename = local_files.pop ) do
        short_name = full_filename.split('/').last
        zipfile.add(short_name, full_filename) unless File.size(full_filename).to_i < MINIMUM_FILE_SIZE
        files_to_delete << full_filename
      end
    end
  end

  def archive_file_name
    @archive_file_name ||= "#{UUID.generate(:compact)[0..8]}images.zip"
  end

  def archive_file_path
    "#{Rails.root.join('public')}"
  end

  def files_to_delete
    @files_to_delete ||= []
  end
end
