

# Change webconsole to authorize via Programmer Basic Auth and allow locally or by ssl
WebConsole::Request.class_eval do
  def from_whitelisted_ip?;
    authenticated = ActionController::HttpAuthentication::Basic.authenticate self do |email, pw|
      Rosie::Programmer.login(email, pw) end
    return authenticated && (ssl? || local?)
  end
end

# Fix magic floating bug by irrational magic something O_o
WebConsole::Middleware.class_eval do
  def acceptable_content_type? headers;
    Mime::Type.parse(headers['Content-Type'].to_s).first == Mime[:html] rescue raise headers.inspect
  end
end

# Add direct rosie template view and edit links
Rails.application.config.web_console.template_paths = Rosie::Engine.root.join('app/views/rosie/web_console')
# remount so it is not
if(!Rails.application.config.web_console.mount_point ||
  Rails.application.config.web_console.mount_point == '/__web_console') then
  Rails.application.config.web_console.mount_point = '/p/wcs'
end
