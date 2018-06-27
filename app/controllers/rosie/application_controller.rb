module Rosie
  class ApplicationController < ActionController::Base
    def self.programmer_authentication_required?; false end

    protect_from_forgery with: :exception
    before_action :programmer_login_and_setup_tools
    around_action :with_cookie_timezone

    helper_method :programmer_component_path, :current_path, :asset_file_path,
      :component_path, :component_url

    def show_detailed_exceptions?; !!session['is_programmer'] end

    def health_check
      if params[:access_token] != HealthCheck.access_token
        render plain: 'prohibited', status: 503
      else
        if HealthCheck.check_for_errors.present?
          render plain: HealthCheck.check_for_errors.join("\n"), status: 500
        else
          render plain: 'success'
        end
      end
    end

    private

    def programmer_component_path component_path;
      url_for only_path: true, controller: :programmer, action: :manage_component,
         path: component_path
    end

    def component_path(params = {})
      params[:controller] = 'client'
      params[:action] = 'render_component_template'
      params[:only_path] = true unless params.has_key?(:only_path)

      result = url_for params
      result = '/' if result == ''
      result
    end

    def component_url(params = {})
      component_path(params.merge(only_path: false))
    end

    def with_cookie_timezone
      if cookies[:timezone]
        Time.use_zone(Time.find_zone(cookies[:timezone])) { yield }
      else yield end
    end

    def programmer_login_and_setup_tools
      Programmer.current = nil
      if self.class.programmer_authentication_required? && !request.ssl? && !request.local? # force ssl to use programmer interface
        raise ActionController::RoutingError.new('Not Found')
      end
      if authenticate_with_http_basic { |email, pw| Programmer.login(email, pw) }
        session['is_programmer'] = true unless session['is_programmer'];
        if (dev_tools = params[:__]).present?
          console if dev_tools =~ /c/
          Component.track_request_components! if dev_tools =~ /t/
          Rack::MiniProfiler.authorize_request if (dev_tools =~ /[pgmaf]/ || params.has_key?(:pp))
          if !params.has_key?(:pp)
            redirect_to(params.merge(pp: true).permit!) if dev_tools =~/p/
            redirect_to(params.merge(pp: 'profile-gc').permit!) if dev_tools =~/g/
            redirect_to(params.merge(pp: 'profile-memory').permit!) if dev_tools =~/m/
            redirect_to(params.merge(pp: 'analyze-memory').permit!) if dev_tools =~/a/
            redirect_to(params.merge(pp: 'flamegraph').permit!) if dev_tools =~/f/
          end
        end
      else
        if self.class.programmer_authentication_required? || session['is_programmer']
          request_http_basic_authentication
        end
      end
    end

    def current_path(overwrite={})
      url_for params.permit!.merge(overwrite).merge(:only_path => true)
    end

    def asset_file_path filename; AssetFile.hashed_path filename; end

  end
end
