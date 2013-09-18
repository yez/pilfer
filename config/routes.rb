ImagePilfer::Application.routes.draw do
  root to: 'index#index'

  post '/pilfer', to: 'index#pilfer'
end
