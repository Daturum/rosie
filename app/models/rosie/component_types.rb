module Rosie
  class ComponentTypes
    def self.types
      @@component_types ||= {
        role:         {formats: 'text', handlers: %w[raw],           context_types: %w[root],         occurence: 'multiple' },
        layout:       {formats: 'html', handlers: %w[erb],           context_types: %w[role],         occurence: 'single' },
        scenario:     {formats: 'html', handlers: %w[erb slim],      context_types: %w[role],         occurence: 'multiple' },
        partial:      {formats: 'html', handlers: %w[erb slim],      context_types: %w[layout scenario], occurence: 'multiple' },
        json_action:  {formats: 'json', handlers: %w[erb],           context_types: %w[scenario],     occurence: 'multiple' },
        autoload_lib: {formats: 'text', handlers: %w[ruby],          context_types: %w[layout scenario], occurence: 'multiple' },
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
          template: '<%= @component.name.humanize %> role description and change log'
        },
        layout: {
          hints: "Use this layout in controller: layout '<%= @component.path %>'",
          template:  <<~LAYOUT_TEMPLATE
            <html>
              <head>
                <title>Hello, <%= @component.base_context.humanize %>!</title>
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
            component_path(role: @component.base_context, scenario: @component.name), target: :_blank %><br>
            #{autoreplace_filepaths_link}
          SCENARIO_HINTS
          template: <<~SCENARIO_TEMPLATE
            <h1>Start scenario</h1>
            <%%= link_to "What's the time?", url_for(json_action: :get_current_time, some_param: 'some_val'),
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
          These JSON actions are called by POST http method.
          <%= link_to 'Test in new window', component_path(
            role: @component.base_context, scenario: @component.parent,
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
          Example: to put 'user/start' scenario to /new_url you can create new user/start/custom_routes component with this code
          class Rosie::UserStartCustomRoutes
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
