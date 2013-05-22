require 'vcr'
require 'webmock'

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path('../../cassettes', __FILE__)
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.ignore_localhost = ture
  config.default_cassette_options = { record: :none, serialize_with: :syck }

  config.filter_sensitive_data('<USER_AGENT>') do |interaction|
    interaction.request.headers['User-Agent'].first
  end
end

WebMock.disable_net_connect!(allow_localhost: true)
