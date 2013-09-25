class NiceUrl

  attr_accessor :raw_url, :base_url, :full_url

  include HTTParty

  def initialize(url)
    self.base_url = ""
    self.full_url = ""
    parse(url) unless url.blank?
  end

  def valid?
    (self.base_url =~ URI::regexp).present? && test_connection
  end

private

  def test_connection
    begin
      response = self.class.get(self.base_url)
    rescue SocketError => e
      return false
    end
    [200, 300, 301, 302].include? response.code
  end

  def parse(url)
    parsed = URI.parse(url)
    if parsed.scheme.present?
      self.full_url = "#{parsed.scheme}://#{URI.split(url)[1..-1].join}"
      self.base_url = "#{parsed.scheme}://#{parsed.host}"
    else
      if parsed.host.present?
        self.base_url = "http://#{parsed.host}"
      else
        self.base_url = "http://#{parsed}"
      end
      self.full_url = "http://#{parsed}"
    end
  end
end
