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

  ##
  # Sets configuration options for accessing the LaunchKey API.
  #
  # @example Configuring LaunchKey.
  #     LaunchKey.configure do |config|
  #       config.domain     = 'http://example.com'
  #       config.app_key    = 12345
  #       config.secret_key = 's3cr3t!'
  #       config.keypair    = File.read('./config/launchkey-keypair.pem')
  #     end
  #
  # @yield [Configuration]
  #   The configuration.
  def configure
    yield(config)
  end

  ##
  # @return [Configuration]
  #   The configuration.
  def config
    @config ||= Configuration.new
  end

  ##
  # Initializes a new LaunchKey API client with supplied `config` and `options`.
  # When no `config` is supplied, {#config} is used.
  #
  # @param [Config] config
  #   The configuration to use.
  #
  # @param [{Symbol => Object}] options
  #   A `Hash` of configuration options to override.
  #
  # @return [Client]
  #   A new LaunchKey client.
  def new(config = LaunchKey.config.dup, options = {})
    Client.new(config, options)
  end

  ##
  # Initializes a default client with options from {#config}. Used for
  # applications with a single LaunchKey app and secret.
  #
  # @return [Client]
  #   A client configured with the default {#config}.
  def client
    @client ||= new(config)
  end

  delegate(*Configuration.public_instance_methods(false), to: :config)
  delegate(*Client.public_instance_methods(false) - [:config], to: :client)
end # LaunchKey
