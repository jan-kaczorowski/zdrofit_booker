HttpLog.configure do |config|
  # Enable or disable all logging
  config.enabled = true
  config.log_connect   = true
  config.log_request   = true
  config.log_headers   = true
  config.log_data      = true
  config.log_status    = true
  config.log_response  = true
  config.log_benchmark = true
end
