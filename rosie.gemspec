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
  s.license     = "APACHE 2.0"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.2.0"

  s.add_development_dependency "pg"
end
