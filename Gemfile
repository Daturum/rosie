source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Declare your gem's dependencies in rosie.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem 'byebug', group: [:development, :test]

# rosemary is build with and tested with puma
gem 'puma'

# adding as development dependency because xlsx is often used
# for configuration storage
gem 'creek'

gem 'geokit-rails'

gem 'numbers_in_words'

# TODO: Remove and make this a new branch
envgems = %(gem 'kmeans-clusterer';gem 'gnuplot')
if envgems
  envgems.split(';').each do |gem_string|
    eval gem_string
  end
end
