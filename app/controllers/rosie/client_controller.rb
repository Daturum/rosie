module Rosie
  class ClientController < ApplicationController
    protect_from_forgery with: :exception, except: [:render_asset, :get_asset_file]
    around_action :with_handling_of_path_not_exists,          only: [:show_page, :render_asset]
    after_action  :inject_request_components,                 only: :show_page
    after_action  :inject_ajax_error_handling_for_programmer, only: :show_page

    def self.programmer_authentication_required?; false end

    @@original_view_paths = view_paths.dup
    def self.reset_and_prepend_component_path path;
      Rails.logger.info "Prepending view path #{path}"
      self.view_paths = @@original_view_paths.dup
      prepend_view_path path
    end

    def get_asset_file
      params[:hashed_path] += '.' + params[:format] if params.has_key? :format
      @file = AssetFile.get_file_by_hashed_path(params[:hashed_path])
      raise ActionController::RoutingError.new('Not Found') unless @file
      expires_in 1.year, :public => true
      send_data(@file.file_contents, type: @file.content_type, filename: @file.filename)
    end

    def show_page
      path = params[:path]
      layout_path = "#{path.split('/')[0]}/layout"
      layout = MemoryStore.fetch_invalidate "layout_path_for_#{path}", Programmer.last_action_timestamp do
        (Component.where(path: layout_path).exists? ? layout_path : nil)
      end
      render template: path, format: params[:format], layout: layout
    end

    def render_asset
      @component = Component.get_asset_component_by_hashed_path(params[:hashed_path])
      raise ActionController::RoutingError.new('Not Found') unless @component
      if @component.format != request.format
        raise "Different formats  (#{request.format.inspect} in request, #{
          @component.format.inspect} in component)"
      end
      expires_in 1.year, :public => true
      handler = @component.handler.in?(%w[sass scss]) ? 'raw' : @component.handler
      render template: @component.path, format: @component.format, handler: @component.handler, layout: nil
    end

    private

    def inject_request_components
      if Component.request_components_tracked?
        response.body = response.body.sub('</body>',
          %(#{render_to_string 'programmer/_request_components_injection'}</body>))
      end
    end

    def inject_ajax_error_handling_for_programmer
      if Programmer.current
        response.body = response.body.sub('</body>',
          %(#{render_to_string 'programmer/_ajax_error_replay_for_programmer'}</body>))
      end
    end

    def with_handling_of_path_not_exists
      begin
        yield
      rescue ActionView::MissingTemplate => error
        raise ActionController::RoutingError.new('Not Found') if !Programmer.current
        raise error
      end
    end
  end
end
