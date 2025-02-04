require "tailwindcss-ruby"

Tailwindcss.configure do |config|
  config.input = "app/assets/stylesheets/application.tailwind.css"
  config.output = "app/assets/builds/tailwind.css"
  config.prefix = ""
end
