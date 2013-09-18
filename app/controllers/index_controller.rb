class IndexController < ApplicationController
  def index
  end

  def pilfer
    pilfer = Pilferer.new(params[:url_to_pilfer])
    file_name = pilfer.scrape_all
    success = file_name.present?

    render json: { success: success, file: file_name}
  end
end
