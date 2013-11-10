require 'spec_helper'

describe LaunchKey::Client do

  let(:config) do
    LaunchKey.config.dup
  end

  let(:client_options) do
    {}
  end

  let(:client) do
    described_class.new(config, client_options)
  end

  describe '#initialize' do

    let(:config) do
      build(:config)
    end

    subject do
      client
    end

    context 'when config supplied' do

      context 'when options supplied' do

        let(:client) do
          described_class.new(config.dup, client_options)
        end

        let(:client_options) do
          {
            http_open_timeout: 1337,
            domain: 'https://myawesomeapp.com'
          }
        end

        it 'merges supplied options into configuration' do
          expect(client.config.to_hash).to eq(
            config.merge(client_options).to_hash
          )
        end
      end
    end

    context 'when config not supplied' do

      let(:client) do
        described_class.new
      end

      before do
        @original_config = LaunchKey.config
        LaunchKey.instance_variable_set :@config, config
      end

      after do
        LaunchKey.instance_variable_set :@config, @original_config
      end

      it 'uses LaunchKey.config by default' do
        expect(client.config.to_hash).to eq(LaunchKey.config.to_hash)
      end

      it 'duplicates LaunchKey.config' do
        expect(client.config.object_id).not_to eq(LaunchKey.config.object_id)
      end
    end
  end

  describe '#authorize' do

    subject(:auth_request) do
      client.authorize(ENV['LAUNCHKEY_TEST_USER'])
    end

    context 'when successful',
      vcr: { cassette_name: 'client/authorize/success' } do

      it 'returns an auth request String' do
        expect(auth_request).to be_a(String)
      end
    end
  end

  describe '#poll_request' do

    let(:auth_request) do
      client.authorize(ENV['LAUNCHKEY_TEST_USER'])
    end

    subject(:poll) do
      client.poll_request(auth_request)
    end

    context 'when auth request invalid',
      vcr: { cassette_name: 'client/poll_request/invalid' } do

      let(:auth_request) do
        'nanners'
      end

      it 'raises AuthRequestNotFoundError' do
        expect {
          poll
        }.to raise_error(LaunchKey::Errors::AuthRequestNotFoundError)
      end
    end

    context 'when auth request pending',
      vcr: { cassette_name: 'client/poll_request/pending' } do

      it 'returns false' do
        expect(poll).to be_false
      end
    end

    context 'when auth request complete',
      vcr: { cassette_name: 'client/poll_request/complete' } do

      it 'returns Hash containing user hash and auth' do
        expect(poll).to include(:user_hash, :auth)
      end
    end
  end

  describe '#authorized?' do

    let(:auth_request) do
      client.authorize(ENV['LAUNCHKEY_TEST_USER'])
    end

    let(:auth_response) do
      client.poll_request(auth_request)
    end

    subject(:authorized) do
      client.authorized?(auth_response[:auth])
    end

    context 'when auth request accepted',
      vcr: { cassette_name: 'client/authorized/accepted' } do

      it 'returns true' do
        expect(authorized).to be_true
      end
    end

    context 'when auth request rejected',
      vcr: { cassette_name: 'client/authorized/rejected' } do

      it 'returns false' do
        expect(authorized).to be_false
      end
    end
  end
end
