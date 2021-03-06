module Rosie
  class ClientController < ApplicationController
    protect_from_forgery with: :exception, except: [:get_asset_file], unless: :is_public_json_request
    around_action :log_partial_events,                        only: :render_component_template
    around_action :with_handling_of_path_not_exists,          only: :render_component_template
    after_action  :inject_request_components,                 only: :render_component_template
    after_action  :inject_ajax_error_handling_for_programmer, only: :render_component_template

    prepend_view_path ComponentTypes.components_directory

    def self.programmer_authentication_required?; false end

    @@original_view_paths = view_paths.dup
    def self.reset_and_prepend_component_path path;
      Rails.logger.info "Prepending view path #{path}"
      self.view_paths = @@original_view_paths.dup
      prepend_view_path path
    end

    def get_asset_file
      params[:hashed_path] += '.' + params[:format] if params.has_key? :format
      @file = AssetFile.get_file_by_hashed_path_with_contents(params[:hashed_path])
      raise ActionController::RoutingError.new('Not Found') unless @file
      expires_in 1.year, :public => true
      contents = @file.file_contents

      #autoreplace asset filepaths inside js or css if needed
      if @file.autoreplace_filepaths
        Rosie::AssetFile.pluck(:filename).each do |filename| if !filename.match(/\.(css|js)$/)
          variants = ["../#{filename}", "./#{filename}", "/#{filename}", filename]
          variants.each do |variant| contents.gsub! variant, asset_file_path(filename) end
        end end
      end

      send_data(contents, type: @file.content_type, filename: @file.filename, disposition: :inline)
    end

    def render_component_template
      role, scenario, json_action = params[:role], params[:scenario], params[:json_action]
      fmt = params[:format] || 'html'
      template_path = ComponentTypes.rails_template_path(role, scenario, json_action)
      component_path = ComponentTypes.component_path(role, scenario, json_action)
      layout_component_path = ComponentTypes.layout_component_path(role, scenario, json_action)
      Component.add_request_component_path component_path

      layout_rails_template_path = ComponentTypes.rails_layout_template_path(role, scenario, json_action, fmt)
      Component.add_request_component_path layout_component_path if layout_rails_template_path

      render template: template_path, format: fmt, layout: layout_rails_template_path
    end

    private

    def is_public_json_request
      params[:json_action].present? && params[:json_action] =~ /_public$/
    end

    def inject_request_components
      if Programmer.current && Component.request_components_tracked?
        response.body = response.body.sub('</body>',
          %(#{render_to_string 'rosie/programmer/_request_components_injection'}</body>))
      end
    end

    def log_partial_events &block
      if Programmer.current && Component.request_components_tracked?
        callback = lambda do |event_name, start_at, end_at, id, payload|
          path = ComponentTypes.get_component_by_rails_template_path(payload[:identifier]).try :path
          Component.add_request_component_path(path) if path
        end
        ActiveSupport::Notifications.subscribed(callback, "render_partial.action_view") do
          block.call
        end
      else
        block.call
      end
    end

    def inject_ajax_error_handling_for_programmer
      if Programmer.current && request.format == 'html'
        response.body = response.body.sub('</body>',
          %(#{render_to_string 'rosie/programmer/_ajax_error_replay_for_programmer', layout: nil}</body>))
      end
    end

    def with_handling_of_path_not_exists
      begin
        yield
      rescue ActionView::MissingTemplate => error
        raise ActionController::RoutingError.new('Not Found')
      end
    end
  end
end
