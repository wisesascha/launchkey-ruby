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

  delegate(*Configuration.public_instance_methods(false), to: :config)

  def new(config, options = {})
    Client.new(config, options)
  end

  def client
    @client ||= new(config)
  end

  def method_missing(method_name, *arguments, &block)
    if client.respond_to?(method_name)
      client.send(method_name, *arguments, &block)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    client.respond_to?(method_name) || super
  end
end # LaunchKey
