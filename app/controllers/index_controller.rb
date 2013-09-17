class IndexController < ApplicationController
  def index
  end

  def pilfer
    pilfer = Pilfer.new(params[:url])
    file_name = pilfer.scrape_all
    success = file_name.present?

    render json: { success: success, file: file_name}
  end

end