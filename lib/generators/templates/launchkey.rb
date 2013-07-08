# Use this initializer to configure LaunchKey.
#
# It is STRONGLY recommended that you store sensitive information such as your
# application secret and keypair passphrase somewhere else. Below, these are
# referenced through environment variables which is common when using services
# such as Heroku and tools like Foreman.
LaunchKey.configure do |config|
  config.domain     = ENV['LAUNCHKEY_DOMAIN']
  config.app_key    = ENV['LAUNCHKEY_APP_KEY']
  config.secret_key = ENV['LAUNCHKEY_SECRET_KEY']
  config.keypair    = File.read Rails.root.join('config/launchkey_keypair.pem')
  config.passphrase = ENV['LAUNCHKEY_KEYPAIR_PASSPHRASE']
end

