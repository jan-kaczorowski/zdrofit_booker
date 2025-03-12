# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Add solid_queue_dashboard assets
Rails.application.config.assets.paths << Gem.loaded_specs['solid_queue_dashboard'].full_gem_path + '/app/assets/stylesheets'
Rails.application.config.assets.paths << Gem.loaded_specs['solid_queue_dashboard'].full_gem_path + '/app/assets/javascripts'
