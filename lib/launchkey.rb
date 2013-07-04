require 'active_support/core_ext'
require 'i18n'

require 'launchkey/version'

require 'launchkey/errors'
require 'launchkey/configuration'
require 'launchkey/requests'
require 'launchkey/client'
require 'launchkey/rsa_key'

# Add English load path by default
I18n.load_path << File.join(File.dirname(__FILE__), 'config', 'locales', 'en.yml')

module LaunchKey
  extend self

  ENDPOINT = 'https://api.launchkey.com/v1/'.freeze

  def configure
    yield(config)
  end

  def config
    @config ||= Configuration.new
  end


  def new(config = nil, options = {})
    Client.new(config, options)
  end

  def client
    @client ||= new(config)
  end

  delegate(*Configuration.public_instance_methods(false), to: :config)
  delegate(*Client.public_instance_methods(false) - [:config], to: :client)
end # LaunchKey
