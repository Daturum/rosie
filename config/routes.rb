Rosie::Engine.routes.draw do
  # Programmer area
  get  'p/readme', to: 'programmer#readme'
  get  'p/cns', to: 'programmer#console', as: :programmer_console
  post 'p/go', to: 'programmer#go'
  post 'p/invite_programmer', to: 'programmer#invite', as: :invite_programmer

  get  'p/files', to: 'programmer#files'
  post 'p/files', to: 'programmer#manage_file'

  get  "p/components", to: "programmer#components"
  post "p/components", to: "programmer#manage_component"
  post "p/autoreplace", to: "programmer#autoreplace_filepaths_in_html_component"
  put  "p/components", to: 'programmer#unlock_editing'

  # User area
  get  'files/(*hashed_path)', to: 'client#get_asset_file'

  match '/', to: 'client#render_component_template', via: [:get, :post], role: "user", scenario: "start"
  match '/(:role(/:scenario(/:json_action)))', to: 'client#render_component_template',
    as: :render_component_template, via: [:get, :post],
      :defaults => { :role => "user", :scenario => "start" }

end
