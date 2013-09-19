class IndexController < ApplicationController

  include ActionView::Helpers::UrlHelper

  def index
  end

  def pilfer
    pilfer = Pilferer.new(params[:url_to_pilfer])

    if pilfer.valid_url?
      file_name = pilfer.scrape_all
      success = file_name.present?
      render json: { success: success, file: link_to("File Download", file_name) }
    else
      success = false
      render json: { success: success, error: "Please enter a correct URL." }
    end
  end
end
