module RapidRack
end

require_relative 'rapid_rack/version'
require_relative 'rapid_rack/with_claims'
require_relative 'rapid_rack/authenticator'
require_relative 'rapid_rack/test_authenticator'
require_relative 'rapid_rack/redis_registry'
require_relative 'rapid_rack/engine' if defined?(Rails)
