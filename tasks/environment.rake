task :environment do
  require 'launchkey'
  require File.expand_path('../../spec/support/config.rb', __FILE__)
  LaunchKeyHelpers.load_config
end
