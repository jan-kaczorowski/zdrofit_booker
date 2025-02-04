require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ZdrofitBooker
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.active_record.encryption.primary_key = "Q2hXD9K9eYX39yYKqZQ3qxz4STbmkWVv"
    config.active_record.encryption.deterministic_key = "aWvhWL6Kx4MxRZ2yNTCKpnxy4PKpbGxn"
    config.active_record.encryption.key_derivation_salt = "xQ3UCpkFQXdgNwpWvXpNqXpndW62tVLr"
    config.active_record.encryption.encrypt_fixtures = true

    # Add the builds directory to the asset paths
    config.assets.paths << Rails.root.join("app/assets/builds")
  end
end
