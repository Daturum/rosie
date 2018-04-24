$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "rosie/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rosie"
  s.version     = Rosie::VERSION
  s.authors     = ["Anton Baronov"]
  s.email       = ["anton.baronov@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Rosie."
  s.description = "TODO: Description of Rosie."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.2.0"

  s.add_development_dependency "sqlite3"
end
