# Change webconsole to authorize via Programmer Basic Auth and allow locally or by ssl
# Put this to application.rb of your Rails app:
# require Rosie::Engine.config.root.join('lib', 'rosie', 'web_console_config.rb')


require 'web_console'

# Allow to debug in production environments (local or ssl requests only)
WebConsole::Request.class_eval do
  def from_whitelisted_ip?;
    programmer_authenticated = ActionController::HttpAuthentication::Basic.authenticate self do |email, pw|
      Rosie::Programmer.login(email, pw) end
    return programmer_authenticated && (ssl? || local?)
  end
end

# Workaround for a magic floating bug
WebConsole::Middleware.class_eval do
  def acceptable_content_type? headers;
    Mime::Type.parse(headers['Content-Type'].to_s).first == Mime[:html] rescue raise headers.inspect
  end
end

# Add direct rosie template view and edit links
Rails.application.config.web_console.template_paths = Rosie::Engine.root.join('app/views/rosie/web_console')
Rails.application.config.web_console.development_only = false
Rails.application.config.web_console.whiny_requests = !Rails.env.production?

# Remount so it is not mounted to obvious standard route
if(!Rails.application.config.web_console.mount_point ||
  Rails.application.config.web_console.mount_point == '/__web_console') then
  Rails.application.config.web_console.mount_point = "#{ENV['ROSIE_MOUNT_PATH']}/p/wcs"
end
