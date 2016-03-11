# rack-timeout config
# rack-timeout-puma: kill threads, not workers
Rack::Timeout.timeout = Integer(ENV['RACK_TIMEOUT'] || 20)