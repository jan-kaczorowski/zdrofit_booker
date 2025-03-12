require "solid_queue_dashboard"

# Configure solid_queue_dashboard
SolidQueueDashboard.configure do |config|
  # You can add authentication or other configuration here
end

# Precompile assets
Rails.application.config.assets.precompile += %w( solid_queue_dashboard/application.css solid_queue_dashboard/application.js )