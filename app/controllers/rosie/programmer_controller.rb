require 'rosie/zip_dir.rb'
module Rosie
  class ProgrammerController < ApplicationController
    def self.programmer_authentication_required?; true end
    include ActionView::Helpers::TextHelper
    after_action only: %w[manage_component manage_file] do Programmer.update_last_action_timestamp; end
    after_action only: %w[components manage_component] do
      @component.update_lock! if @component && @component.persisted? && !@component.get_locking_programmer
    end

    def readme
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
        if params[:path] == 'NEW' || !Component.exists?
          @component = Component.new(
            component_type: (params[:type] ||
              Component.component_types.keys.first))
          if(params[:context].blank?)
            new_component_context = @component.permitted_contexts[0]

            referer_context = CGI::parse(URI::parse(request.referer).query)['path'][0]
            if referer_context.in?(@component.permitted_contexts)
              new_component_context = referer_context
            end

            redirect_to current_path(context: new_component_context)
          else
            name = (params[:name] || '').parameterize.underscore
            @component.set_context_and_name(params[:context], name)
            @component.body = ERB.new(
              ComponentTypes.templates[@component.component_type][:template], nil, "%"
            ).result(binding).strip
          end
        else
          redirect_to path: Component.first.path
        end
      end
    end

    def manage_component
      raise 'Commit message is needed' if params[:commit_message].blank?

      Component.transaction do

        # deleting component
        if params[:delete] && @component = Component.find_by(path: params[:delete])
          @component.version_commit_message = params[:commit_message]
          @component.destroy!
          render js: "window.location = '?'";
          return
        end

        # creating or updating component
        raise "No original path given" unless params.has_key?(:original_path)
        original_path = params[:original_path]

        @component = ((original_path != "") ? Component.find_by(path: original_path) :
          Component.new(component_type: params[:new_component_type]));

        if @component.persisted? && (params[:latest_version_timestamp].to_i != @component.latest_version_timestamp)
          raise "This component was modified #{params[:latest_version_timestamp].to_i} #{@component.latest_version_timestamp}"
        end

        component_had_errors_before_update = @component.loading_error.present?

        @component.set_context_and_name(params[:context], params[:name])

        @component.update!(
          version_commit_message: params[:commit_message],
          body: params[:body],
          format: params[:format],
          handler: params[:handler])

        @component.delete_recent_versions_of_current_programmer_except_latest

        ComponentLoaderMiddleware.current.load_or_reload_all_components

        @component.reload

        if(original_path != @component.path)
          render js: "window.location = '?path=#{@component.path}'"
        elsif((@component.loading_error.present?) || (component_had_errors_before_update))
          render js: "window.location.reload()";
        else
          render js: "$('[data-latest-version-timestamp]').data('latest-version-timestamp', #{
            @component.latest_version_timestamp}); window.setOrResetLockTimeout();"
        end
      end
    end

    def unlock_editing
      Programmer.transaction do
        if params[:unlock] && @component = Component.find_by(path: params[:unlock])
          @component.unlock_editing!
          render plain: 'OK'
        end
      end
    end

    def files
      file_role = params[:file_role].presence
      @files = Rosie::AssetFile.order('updated_at').where(file_role: file_role)
    end

    def manage_file
      AssetFile.transaction do
        # deleting file
        if params[:delete] && AssetFile.where(filename: params[:delete]).exists?
          AssetFile.where(filename: params[:delete]).delete_all
          render js: "window.location = '?'";
          return
        end

        # saving file
        params[:files].each do |file|
          # try to get the directory name from headers and add it to filename
          file.original_filename = URI::decode(file.headers.scan(/filename="([^"]+)"/)[0][0]) rescue Rails.logger.info(
            "Could not get original filename with directory for #{file.headers}")

          # ignore outer directory if needed
          if params[:remove_outer_directory_from_filepath] && file.original_filename.include?('/')
            segments = file.original_filename.split('/')
            file.original_filename = segments[1..-1].join('/')
          end

          # prepend paths
          if params[:prepend_path].present?
            prepended_path = params[:prepend_path]
            prepended_path = prepended_path[1..-1] if prepended_path[0]=='/'
            prepended_path = prepended_path+'/' if prepended_path[-1] != '/'
            file.original_filename = "#{prepended_path}#{file.original_filename}"
          end

          # autoreplace filepaths in css and js files
          autoreplace = nil
          if params[:autoreplace_filepaths_in_css_and_js_files]
            autoreplace = AssetFile.css_or_js?(file.original_filename)
          end

          # rewrite
          AssetFile.where(filename: file.original_filename).delete_all if params[:rewrite]
          AssetFile.new(file: file, file_role: params[:file_role], autoreplace_filepaths: autoreplace).save!
        end

        Programmer.update_last_action_timestamp
      end
      redirect_back fallback_location: '/p/files'
    end

    def autoreplace_filepaths_in_html_component
      component = Component.find_by(path: params[:component_path])
      body = component.body
      Rosie::AssetFile.pluck(:filename).each do |filename|
        variants = ["../#{filename}", "./#{filename}", "/#{filename}", filename]
        variants.each do |variant| body.gsub! variant, "<%=asset_file_path('#{filename}')%>" end
      end
      component.update_attribute :body, body

      Programmer.update_last_action_timestamp
      render js: "alert('success'); window.location.reload(true)";
    end

    def search
      query = params[:q]
      if query.blank? || query.length < 3;
        @components = nil
      else
        @components = Component.where('body ILIKE ?', "%#{params[:q]}%");
      end
    end

    def download_role_files
      # create zip file with directory of all role components
      role = params[:role]
      raise('No such role - ' + role) unless File.exists? Rails.root.join("app/interfaces/#{role}/#{role}.txt")
      temp_file = Tempfile.new("#{role}.zip")

      ZipDir.new(Rails.root.join("app/interfaces/#{role}"), temp_file.path).write

      send_data(File.read(temp_file), filename: "#{role}.zip", type: 'application/zip')

      temp_file.close
      temp_file.unlink
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
