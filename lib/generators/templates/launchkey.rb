# Use this initializer to configure LaunchKey.
#
# It is STRONGLY recommended that you store sensitive information such as your
# application secret and keypair passphrase somewhere else. Below, these are
# referenced through environment variables which is common when using services
# such as Heroku and tools like Foreman.
LaunchKey.configure do |config|
  config.domain     = ENV['LAUNCHKEY_DOMAIN']
  config.app_id     = ENV['LAUNCHKEY_APP_ID']
  config.app_secret = ENV['LAUNCHKEY_APP_SECRET']
  config.keypair    = File.read Rails.root.join('config/launchkey_keypair.pem')
  config.passphrase = ENV['LAUNCHKEY_KEYPAIR_PASSPHRASE']
end

