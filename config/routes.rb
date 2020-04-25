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
  put  "p/components", to: 'programmer#unlock_editing'
  patch  "p/components", to: 'programmer#sync_components'
  post "p/autoreplace", to: "programmer#autoreplace_filepaths_in_html_component"
  get  "p/download_role_files", to: 'programmer#download_role_files'

  get  "p/search", to: "programmer#search"

  # User area
  get  'files/(*hashed_path)', to: 'client#get_asset_file'

  begin

    if Rosie::Component.table_exists?

      #Drawing custom routes
      Rosie::Component.where("path LIKE ?", "%/custom_routes").each do |c|
        Rails.logger.info "Loading routes from #{c.path}"
        route_class = "Rosie::#{c.path.split('/').map(&:camelcase).join('')}".safe_constantize
        if !route_class
          Rails.logger.info "Could not load class from #{c.path}"
        else
          begin
            route_class.draw self
          rescue => e
            Rails.logger.info "Could not load routes from class #{c.path}: #{e.message}\n#{e.backtrace.join("\n")}"
          end
        end
      end

      #Drawing user#<scenario> routes
      Rosie::Component.where(component_type: 'scenario').where("path LIKE ?", "user/%").each do |c|
        next if c.name == 'start'
        Rails.logger.info "Drawing user root route #{c.path}"
        match "/#{c.name}", to: 'client#render_component_template', via: [:get, :post], role: "user", scenario: c.name
      end
    end

    match '/', to: 'client#render_component_template', via: [:get, :post], role: "user", scenario: "start"
    match '/(:role(/:scenario(/:json_action)))', to: 'client#render_component_template',
        via: [:get, :post],
        :defaults => { :role => "user", :scenario => "start" }
  rescue => e
    Rails.logger.info "Could not load client routes: #{e.message}\n#{e.backtrace.join("\n")}"
  end

end
