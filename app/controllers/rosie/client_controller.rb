module Rosie
  class ClientController < ApplicationController
    protect_from_forgery with: :exception, except: [:get_asset_file]
    around_action :with_handling_of_path_not_exists,          only: :render_component_template
    after_action  :inject_request_components,                 only: :render_component_template
    after_action  :inject_ajax_error_handling_for_programmer, only: :render_component_template

    prepend_view_path Rails.root.join('app', 'interfaces')

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
      path = [params[:role],params[:scenario],params[:json_action]].reject(&:blank?).join('/')
      fmt = params[:format] || 'html'
      layout_path = "#{params[:role]}/layout"
      layout = MemoryStore.fetch_invalidate "layout_path_for_#{path}_#{fmt}", Programmer.last_action_timestamp do
        (Component.where(path: layout_path, format: fmt).exists? ? layout_path : nil)
      end
      render template: path, format: fmt, layout: layout
    end

    private

    def inject_request_components
      if Component.request_components_tracked?
        response.body = response.body.sub('</body>',
          %(#{render_to_string 'rosie/programmer/_request_components_injection'}</body>))
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
