# Be sure to restart your server when you modify this file.

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile +=
  %w(rosie/programmer.css rosie/programmer.js rosie/application_jquery.js)
