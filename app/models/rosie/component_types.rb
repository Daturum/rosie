module Rosie
  class ComponentTypes
    def self.types
      @@component_types ||= {
        role:         {formats: 'text', handlers: %w[raw],           context_types: %w[root],         occurence: 'multiple' },
        autoload_lib: {formats: 'text', handlers: %w[ruby],          context_types: %w[role],         occurence: 'multiple' },
        layout:       {formats: 'html', handlers: %w[erb],           context_types: %w[role],         occurence: 'single' },
        scenario:     {formats: 'html', handlers: %w[erb slim],      context_types: %w[role],         occurence: 'multiple' },
        partial:      {formats: 'html', handlers: %w[erb slim],      context_types: %w[layout scenario], occurence: 'multiple' },
        json_action:  {formats: 'json', handlers: %w[erb],           context_types: %w[scenario],     occurence: 'multiple' }
      }.with_indifferent_access.freeze
    end

    def self.templates
      autoreplace_filepaths_link =  <<~AUTOREPLACE_LINK
        <%= link_to 'Autoreplace filepaths to dynamically generated for uploaded files',
          url_for(controller: 'rosie/programmer', action: 'autoreplace_filepaths_in_html_component',
          component_path: @component.path), method: :post, remote: true, confirm: "Are you sure?" %>
      AUTOREPLACE_LINK

      @@component_templates ||= {
        role: {
          prompt: 'Enter role name underscored (e.g. admins, moderators, report_viewers)',
          hints: "This is role description. Write here main things to consider and log changes.",
          template: <<~ROLE_TEMPLATE
            <%= @component.name.humanize %> role description

            CHANGE LOG
            <%= Programmer.code_change_description('Role created') %>
          ROLE_TEMPLATE
        },
        layout: {
          hints: %(Render template within this layout: <%%= yield %><br/>
            Use another layout (e.g. user/layout): <%%= render template: 'layouts/user/layout' %><br/>
            #{autoreplace_filepaths_link}),
          template:  <<~LAYOUT_TEMPLATE
            <html>
              <head>
                <title>Hello, <%= @component.root_context.humanize %>!</title>
                <%%= csrf_meta_tags %>
                <%%= stylesheet_link_tag    'rosie/application', media: 'all', 'data-turbolinks-track': 'reload'  %>
                <%%= javascript_include_tag 'rosie/application_jquery', 'data-turbolinks-track': 'reload'  %>
              </head>
              <body>
                <%%= yield %>
              </body>
            </html>
          LAYOUT_TEMPLATE
        },
        scenario: {
          prompt: 'Enter scenario name underscored (e.g. manage_blog_posts, check_user_reports)',
          hints: <<~SCENARIO_HINTS,
            Run this scenario: <%= link_to @component.path,
            component_path(role: @component.root_context, scenario: @component.name), target: :_blank %><br>
            #{autoreplace_filepaths_link}
          SCENARIO_HINTS
          template: <<~SCENARIO_TEMPLATE
            <h1><%= @component.name.humanize%> scenario</h1>
            <%%= link_to "What's the time?", url_for(format: :json, json_action: :get_current_time, some_param: 'some_val'),
            	id: "get_time_link", method: 'POST', remote: true, data:{type: :json, disable_with: 'Please wait...'} %>
            <script>
              $(document).on('ajax:success', '#get_time_link', function(event, data, status, xhr) {
                $(this).after('<br/>'+data.time);
              });
            </script>
          SCENARIO_TEMPLATE
        },
        partial: {
          prompt: 'Enter partial name underscored (e.g. blog_post, moderator_actions)',
          template: <<~PARTIAL_TEMPLATE,
            <div id="<%= @component.name %>">
              Hi, I am a <%= @component.name.humanize %> partial
            </div>
          PARTIAL_TEMPLATE
          hints: <<~PARTIAL_HINTS
            Use this partial:
            <%%= render '<%= @component.path %>', param1: value1, param2: value2...' %>
            <br/>#{autoreplace_filepaths_link}
          PARTIAL_HINTS
        },
        json_action: {
          template: "<%% result = {time: Time.now.to_s('ddMMyyyy')} %>\n<%%= result.to_json.html_safe %>",
          hints: <<~ACTION_HINTS
          These JSON actions are used for gettime JSON answers from backed.
          Include `_public' in JSON action name to allow external POST requests (disable csrf check)
          <%= link_to 'Test in new window', component_path(
            role: @component.root_context, scenario: @component.parent,
            json_action: @component.name, format: @component.format),
            target: "c\#{@component.try :id}", method: :post %><br/>
          ACTION_HINTS
        },
        autoload_lib: {
          prompt: 'Enter library name underscored (e.g. email_settings, queue_initializer)',
          template: <<~LIB_TEMPLATE,
            class Rosie::<%= @component.path.split('/').map(&:camelcase).join('') %>
              # write your code here
            end
          LIB_TEMPLATE
          hints: <<~LIB_HINTS
          <pre>
          Autoload lib is a component to store generic purpose code that is autoloaded on application initialization.
          Autoload lib is loaded in context of hosting application.
          Use autoload lib to:
          - create code libraries to prepare ViewModels for scenarios (MVVM architecture)
          - control access to json actions via augmenting Rosie::ClientController
          - define custom layouts for scenarios rendering
          - control or redefine engine routes (use with caution)
          Example: to put 'user/start' scenario to /new_url you can create new user/custom_routes component with this code
          class Rosie::UserCustomRoutes
            def self.draw routes
              routes.match 'new_url', to: 'client#render_component_template', :role => "user", :scenario => "start", via: [:get, :post]
            end
            Rails.application.routes_reloader.reload!
          end

          DO NOT use autoload to:
          - write slow code and code that calls external services (the load timeout is #{
            ComponentLoaderMiddleware.code_loading_timeout_in_seconds} seconds)
          - write complex business logic (do it in hosting application)
          - monkey patch, configure or anyhow redefine behavior of hosting application
          - store large constants or data sets
          </pre>
          LIB_HINTS
        }
      }.with_indifferent_access.freeze
    end

    ##############################################################################
    # file paths, component paths and rails template paths
    ##############################################################################

    def self.components_directory
      Rails.root.join('app','interfaces')
    end

    EXTENSIONS_TO_FORMAT_AND_HANDLER_EXCEPTIONS = {
      'txt' => {format: 'text', handler: 'raw' },
      'rb'  => {format: 'text', handler: 'ruby' }
    }

    def self.get_format_and_handler_by_file_extensions extensions
      if EXTENSIONS_TO_FORMAT_AND_HANDLER_EXCEPTIONS[extensions]
        EXTENSIONS_TO_FORMAT_AND_HANDLER_EXCEPTIONS[extensions]
      else
        format, handler = extensions.split('.')
        {format: format, handler: handler}
      end
    end

    def self.get_file_extensions_by_format_and_handler format, handler
      EXTENSIONS_TO_FORMAT_AND_HANDLER_EXCEPTIONS.each do |ext, fh|
        return ext if fh[:format] == format && fh[:handler] == handler
      end
      "#{format}.#{handler}"
    end

    def self.relative_filepath component
      is_in_self_directory = component.component_type.in? self.types.map{|k,v| v[:context_types]}.flatten
      path = "#{component.path}#{ '/'+component.name if is_in_self_directory}.#{
        get_file_extensions_by_format_and_handler(component.format, component.handler)}"
      if component.component_type == 'partial'
        segments = path.split('/')
        segments[-1] = "_#{segments[-1]}"
        path = segments.join('/')
      end
      path
    end

    def self.absolute_filepath component
      self.components_directory.join(self.relative_filepath component).to_s
    end

    def self.component_path role, scenario=nil, json_action=nil
      if role && scenario && json_action
        "#{role}/#{scenario}/#{json_action}"
      elsif role && scenario && !json_action
        "#{role}/#{scenario}"
      else role end
    end

    def self.rails_template_path role, scenario=nil, json_action=nil
      result = self.component_path(role, scenario, json_action)
      result += '/'+scenario if scenario && !json_action
      result
    end

    def self.layout_component_path role, scenario=nil, json_action=nil
      "#{role}/layout"
    end

    def self.rails_layout_template_path role, scenario=nil, json_action=nil, format=nil
      component_path = self.component_path(role,  scenario, json_action)
      MemoryStore.fetch_invalidate "layout_path_for_#{component_path}_#{format}", Programmer.last_action_timestamp do
        layout_path = self.layout_component_path(role,  scenario, json_action)
        layout_component = Component.where(path: layout_path, format: format).first
        if layout_component
          ComponentTypes.relative_filepath layout_component
        else nil end
      end
    end

    def self.get_component_by_rails_template_path template_filepath, init_new: false
      template_filepath = template_filepath.sub(/^#{self.components_directory.to_s}\//,'')
      result = Component.where('path ilike ?',"#{template_filepath.split('/')[0]}/%").map do |c|
        [self.relative_filepath(c), c]
      end.to_h[template_filepath]

      if result; result; elsif init_new
        # here we try to infer which component_type corresponds to a given template_filepath
        directory, _, filename_with_extensions = template_filepath.rpartition('/')
        role = directory.split('/')[0]
        component_name, extensions = filename_with_extensions.split('.', 2)
        handler_and_format = get_format_and_handler_by_file_extensions(extensions)

        component_type = nil
        result_component = nil

        permitted_types_and_paths = self.types.map do |component_type, type_description|
          # count all permitted contexts of type in given role
          permitted_contexts_within_role = Component.new(
            component_type: component_type,
            handler: handler_and_format[:handler],
            format: handler_and_format[:format]
          ).permitted_contexts.select{|ctx| (ctx == role) || ctx.start_with?("#{role}/") }

          possible_paths = permitted_contexts_within_role.map do |ctx|
            # new component within this context is valid and template path corresponds
            path = "#{ctx}/#{component_name}"
            test_component = Component.new(
              component_type: component_type,
              path: path,
              handler: handler_and_format[:handler],
              format: handler_and_format[:format],
              version_commit_message: 'test'
            )
            if test_component.valid? && (relative_filepath(test_component) == template_filepath)
              test_component.version_commit_message = nil
              result_component = test_component
              path
            end
          end.reject(&:blank?)

          [component_type, possible_paths]
        end.reject{|k,v| v.blank?}

        if permitted_types_and_paths.flatten.count != 2
          raise "Cannot infer component type from sync file '#{template_filepath
                  }' (possible types found: #{permitted_types_and_paths.inspect})"
        else
          result_component
        end
      end
    end



    def self.seed_db_on_first_request
      if 'Rosie::Component'.safe_constantize.try :table_exists?
        Rails.logger.info "Seeding the database on first request"
        [ %w[role user text raw],
          %w[layout user/layout html erb],
          %w[scenario user/start html erb],
          %w[json_action user/start/get_current_time json erb]
        ].each do |component_info|
          component_type, path, component_format, handler = component_info
          @component = Component.create(component_type: component_type,
            path: path, format: component_format, handler: handler)
          @component.update_attribute(:body,
            ERB.new(self.templates[component_type.to_sym][:template], nil, "%" ).result(binding).strip)
        end
      end
    end
  end
end
