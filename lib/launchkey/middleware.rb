require 'launchkey/middleware/pinger'

Faraday.register_middleware :request,
  launchkey_pinger: -> { LaunchKey::Middleware::Pinger }
