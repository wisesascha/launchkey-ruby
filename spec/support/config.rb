require 'erb'
require 'yaml'

module LaunchKeyHelpers
  extend self

  def load_config
    LaunchKey.config.merge!(config_options).tap do |c|
      begin
        c.keypair
      rescue LaunchKey::Errors::PrivateKeyMissing
        warn $!.to_s
        warn "Defaulting to a randomly generated keypair. Don't be surprised if tests break."

        c.keypair = LaunchKey::RSAKey.generate
      end
    end
  end

  private

  def config_file
    @config_file ||= begin
      if File.exist?(File.expand_path('../../config.yml', __FILE__))
        File.expand_path('../../config.yml', __FILE__)
      else
        warn <<-MESSAGE.strip_heredoc
          A developer-specific configuration was not found in spec/config.yml. Please
          copy spec/config.sample.yml to spec/config.yml and edit your details.
        MESSAGE
        File.expand_path('../../config.sample.yml', __FILE__)
      end
    end
  end

  def config_options
    YAML.load(ERB.new(File.read(config_file)).result)
  end
end
