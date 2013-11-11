require 'vcr'
require 'webmock'

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path('../../cassettes', __FILE__)
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    record: ENV['CI'] ? :none : :once,
    match_requests_on: [
      :method,
      VCR.request_matchers.uri_without_params(:secret_key, :signature)
    ]
  }
  config.hook_into :webmock
  config.ignore_localhost = true

  config.filter_sensitive_data(':user_agent:') do |interaction|
    interaction.request.headers['User-Agent'].first
  end

  config.filter_sensitive_data(':app_key:') { LaunchKey.config.app_key }

  config.filter_sensitive_data(':secret_key:') do |interaction|
    interaction.request.uri.match(%r{secret_key=([a-z0-9=/%]+)&?}i).try(:[], 1)
  end

  config.filter_sensitive_data(':signature:') do |interaction|
    interaction.request.uri.match(%r{signature=([a-z0-9=/%]+)&?}i).try(:[], 1)
  end

  config.filter_sensitive_data(':test_user:') { ENV['LAUNCHKEY_TEST_USER'] }
end

WebMock.disable_net_connect!(allow_localhost: true)
