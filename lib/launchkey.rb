require 'active_support/core_ext/module/delegation'

require 'launchkey/version'

require 'launchkey/errors'
require 'launchkey/configuration'

# Add English load path by default
I18n.load_path << File.join(File.dirname(__FILE__), 'config', 'locales', 'en.yml')

module LaunchKey
  extend self

  def configure
    yield(config)
  end

  def config
    @config ||= Configuration.new
  end

  delegate(*Configuration.public_instance_methods(false), to: :config)
end # LaunchKey
