$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

unless ENV['CI']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
  end
end

require 'rspec'
require 'ffaker'
require 'factory_girl'
require 'yaml'

CONFIG_FILE = if File.exist?(File.expand_path('../config.yml', __FILE__))
  File.expand_path('../config.yml', __FILE__)
else
  warn 'A developer-specific configuration was not found in spec/config.yml. '+
       'Please copy spec/config.sample.yml to spec/config.yml and edit your details.'
  File.expand_path('../config.sample.yml', __FILE__)
end

LAUNCHKEY_CONFIG = YAML.load(File.read(CONFIG_FILE))

require 'launchkey'

RSpec.configure do |config|
  include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    FactoryGirl.find_definitions
  end

  config.before(:each) do
    LAUNCHKEY_CONFIG.each do |option, value|
      LaunchKey.config.send :"#{option}=", value
    end
  end

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
