Rosie::Engine.routes.draw do
  # test
  root to: 'application#home'

  # Programmer area
  get 'p/readme', to: 'programmer#readme'
  get 'p/cns', to: 'programmer#console', as: :programmer_console
  post 'p/go', to: 'programmer#go'
  post '/p/invite_programmer', to: 'programmer#invite', as: :invite_programmer
  
  get 'p/files', to: 'programmer#files'
  post 'p/files', to: 'programmer#manage_file'


  get 'asset_files/(*hashed_path)', to: 'client#get_asset_file'
  get 'rosie_assets/(*hashed_path)', to: 'client#render_asset', constraints: lambda { |req|
    (req.format == :css) || (req.format == :js) }

end
