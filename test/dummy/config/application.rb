require_relative 'boot'

require 'rails/all'

require 'rack/cache'

Bundler.require(*Rails.groups)
require "rosie"

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Use Rack::Cache for asset files
    config.middleware.use Rack::Cache,
      :verbose => true,
      :metastore   => 'file:tmp/cache/rack/meta',
      :entitystore => 'file:tmp/cache/rack/body'

    require Rosie::Engine.config.root.join('lib', 'rosie', 'web_console_config.rb')



  end
end
