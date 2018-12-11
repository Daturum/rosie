$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "rosie/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rosie"
  s.version     = Rosie::VERSION
  s.authors     = ["Anton Baronov"]
  s.email       = ["anton.baronov@gmail.com"]
  s.homepage    = "https://github.com/Daturum/rosie"
  s.summary     = "Rosie is a tool (a Rails engine) for lightning-fast prototyping and interface building."
  s.description = "Rosie enables a GoogleDoc-like write-and-check interface development in browser with Ruby on Rails."
  s.license     = "Apache 2.0"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.2.0"
  # Audit out models
  s.add_dependency "paper_trail"

  # Use has_secure_password
  s.add_dependency 'bcrypt', '~> 3.1.7'

  # Request store to store data in Thread.current per request gem 'request_store'
  s.add_dependency 'request_store'

  # Miniprofiler & co
  s.add_dependency 'rack-mini-profiler'
  s.add_dependency 'memory_profiler'
  s.add_dependency 'flamegraph'
  s.add_dependency 'stackprof'     # For Ruby MRI 2.1+
  s.add_dependency 'fast_stack'    # For Ruby MRI 2.0

  s.add_dependency 'jquery-rails'

  s.add_dependency "pg" # if you wish to help making rosie dbms-agnostic, please prepare MRs for TODO pg_dependency

  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  s.add_dependency 'web-console', '>= 3.3.0'

  # Add rack-cache for asset_files
  s.add_dependency 'rack-cache'

  # Pony gem for convenient sending emails
  s.add_dependency 'pony'

  s.add_dependency 'geokit-rails'

end
