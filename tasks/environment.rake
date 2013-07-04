task :environment do
  require 'launchkey'
  require 'yaml'

  config_file = File.expand_path('../../spec/config.yml', __FILE__)
  if File.exist?(config_file)
    config = YAML.load(File.read(config_file))
    config.each do |option, value|
      LaunchKey.config.send :"#{option}=", value
    end
  end
end
