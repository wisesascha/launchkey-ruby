require 'active_support/core_ext'
require 'i18n'

require 'launchkey/version'

require 'launchkey/errors'
require 'launchkey/configuration'
require 'launchkey/util'

# Add English load path by default
I18n.load_path << File.join(File.dirname(__FILE__), 'config', 'locales', 'en.yml')

module LaunchKey
  extend self

  ENDPOINT      = 'https://api.launchkey.com/v1/'.freeze
  TEST_ENDPOINT = 'http://staging-api.launchkey.com/v1/'.freeze

  def configure
    yield(config)
  end

  def config
    @config ||= Configuration.new
  end

  delegate(*Configuration.public_instance_methods(false), to: :config)
end # LaunchKey
