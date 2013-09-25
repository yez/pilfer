class Image
  include HTTParty

  attr_accessor :source, :raw_nokogiri_data, :base_url

  def download
    self.class.get(source)
  end

  def initialize(raw_nokogiri_data, base_url)
    self.raw_nokogiri_data = raw_nokogiri_data
    self.base_url = base_url
    extract_source
  end

  def extension
    end_of_url_array = name.split('.')
    (end_of_url_array.count < 1) ? "jpg" : end_of_url_array.last.gsub(/\?.*/, '')
  end

  def name
    @name ||= source.split('/').last
  end

  def local_file_name
    @local_file_name ||= "tmp/#{UUID.generate(:compact)[0..5]}#{name.split('.').first[0..30]}.#{extension}"
  end

  def extract_source
    data_defer_src = raw_nokogiri_data.attributes["data-defer-src"]

    if data_defer_src.present?
      self.source = data_defer_src.value
    else
      raw_nokogiri_data.attributes.each do |name, attribute|
        if name == 'src'
          parsed_src = URI.parse(attribute.value)
          self.source = begin
            if parsed_src.scheme.nil? && parsed_src.host.nil?
              if attribute.value[0] == "/"
                "#{self.base_url}#{attribute.value}"
              else
                "#{self.base_url}/#{attribute.value}"
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
