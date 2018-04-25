module Rosie
  class ProgrammerController < ApplicationController
    def self.programmer_authentication_required?; true end
    include ActionView::Helpers::TextHelper
    before_action only: %w[components manage_component] do @component_scope = params[:component_scope] end
    after_action only: %w[manage_component manage_file] do Programmer.update_last_action_timestamp; end
    after_action only: %w[components manage_component] do
      @component.update_lock! if @component && @component.persisted? && !@component.get_locking_programmer
    end

    def guide
      render html: raw(%(<pre>#{
          File.read(Rosie::Engine.root.join 'README.md')}</pre>)),
        layout: 'rosie/programmer'
    end

    def console
    end

    def invite
      email = params[:email]
      invited_programmer = Programmer.find_or_initialize_by(email: email)

      ActiveRecord::Base.transaction do
        if(invited_programmer.persisted?) # if re-inviting existing programmer
          invited_programmer.touch # we touch the record
        elsif(invited_programmer.new_record? && invited_programmer.tap{|p| p.password = 'temporary1'}.save) # if new and valid record
          invited_programmer.update_attribute(:password_digest, nil)  #   we reset password_digest to nil until login
        end
      end

      if invited_programmer.persisted?
        render js: "alert('Invitation is valid until #{Programmer.invitation_duration.from_now.to_s :short}')"
      elsif !invited_programmer.valid?
        render js: "alert('Could not save programmer: #{invited_programmer.errors.inspect}')"
      end
    end

    def go # console eval
      eval_text = params['txt']
      result = nil
      stdout = with_captured_stdout do
        result = begin
          self.instance_eval(eval_text, 'console_text', 1).inspect;
        rescue Exception => ex;
          if params[:debug]; raise ex end
          apptrace = $!.backtrace.map { |s|
            (s =~ /\/app\//) ? "app/#{s.split('/app/', 2).last}" : nil
          }.reject(&:blank?).join("\n")

          error_with_trace = %(#{ERB::Util.html_escape($!.inspect)}\n \n <span class="apptrace">#{apptrace}</span>) +
          %(<br/><a href="#" onclick="$(this).hide().prevAll('br,.apptrace').hide().nextAll('.fulltrace').fadeIn(); return false;">#{
          "Show full stack trace"}</a><br/><a href="#" onclick="debug(); return false">Debug</a>
          <span class="fulltrace" style="display:none;">#{
          $!.backtrace.join("\n")}</span>)

          error_with_trace.html_safe
        end
      end
      render plain: "#{ERB::Util.html_escape(eval_text)}<br/>#{
        simple_format(ERB::Util.html_escape(stdout ? "\n \n #{stdout} \n" : ''), {}, {wrapper_tag: 'span'})}=> #{
        simple_format(ERB::Util.html_escape(result), {}, {wrapper_tag: 'span', sanitize: false})}"
    end

    def components
      if params[:path].blank? || (@component = Component.find_by(path: params[:path])).blank?
        if params[:path] == 'NEW' || !Component.where(component_scope: @component_scope).exists?
          @component = Component.new(
            component_scope: @component_scope,
            component_type: (params[:type] ||
              Component.component_types[@component_scope].keys.first))
          if(params[:context].blank?)
            redirect_to current_path(context: @component.permitted_contexts[0])
          else
            name = (params[:name] || '').parameterize.underscore
            @component.set_context_and_name(params[:context], name)
            @component.body = ERB.new(
              ComponentTypes.templates[@component.component_type][:template], nil, "%"
            ).result(binding).strip
          end
        else
          redirect_to path: Component.where(component_scope: @component_scope).first.path
        end
      end
    end

    def manage_component
      # deleting component
      if params[:delete] && @component = Component.find_by(path: params[:delete])
        @component.destroy!
        render js: "window.location = '?'";
        return
      end

      # creating or updating component
      raise "No original path given" unless params.has_key?(:original_path)
      original_path = params[:original_path]
      @component = ((original_path != "") ? Component.find_by(path: original_path) :
        Component.new(component_scope: @component_scope, component_type: params[:new_component_type]));

      if @component.persisted? && (params[:latest_version_timestamp].to_i != @component.latest_version_timestamp)
        raise "This component was modified #{params[:latest_version_timestamp].to_i} #{@component.latest_version_timestamp}"
      end

      component_had_errors_before_update = @component.loading_error.present?

      @component.set_context_and_name(params[:context], params[:name])

      @component.update!(
        body: params[:body],
        format: params[:format],
        handler: params[:handler])

      @component.delete_recent_versions_of_current_programmer_except_latest

      ComponentLoaderMiddleware.current.load_or_reload @component

      if(original_path != @component.path)
        render js: "window.location = '?path=#{@component.path}'"
      elsif((@component.loading_error.present?) || (component_had_errors_before_update))
        render js: "window.location.reload()";
      else
        render js: "$('[data-latest-version-timestamp]').data('latest-version-timestamp', #{
          @component.latest_version_timestamp}); window.setOrResetLockTimeout();"
      end
    end

    def redirect_to_current_hashed_asset_path
      redirect_to Component.hashed_http_path(params[:path])
    end

    def unlock_editing
      if params[:unlock] && @component = Component.find_by(path: params[:unlock])
        @component.unlock_editing!
        render plain: 'OK'
      end
    end

    def files
    end

    def manage_file
      # deleting file
      if params[:delete] && @file = AssetFile.find_by(filename: params[:delete])
        @file.destroy!
        render js: "window.location = '?'";
        return
      end

      # saving file
      params[:files].each do |file|
        AssetFile[file.original_filename].try(:destroy!) if params[:rewrite]
        AssetFile.new(file: file).save!
      end
      redirect_back fallback_location: root_path
    end

    private

    def with_captured_stdout
      old_stdout = $stdout
      $stdout = StringIO.new('','w')
      yield
      $stdout.string
    ensure
      $stdout = old_stdout
    end

  end
end
