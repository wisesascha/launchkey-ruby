require 'spec_helper'

describe LaunchKey::Middleware::SignedRequest do

  let(:app) do
    double('app')
  end

  let(:client) do
    double(LaunchKey::Client)
  end

  subject(:middleware) do
    described_class.new(app, client)
  end

  describe '#initialize' do

    it 'initializes with a supplied app and client' do
      expect(middleware.client).to eq(client)
    end
  end

  describe '#call' do

    let(:client) do
      double(
        LaunchKey::Client,
        config: config, ping_timestamp: ping_timestamp
      )
    end

    let(:ping_timestamp) do
      (Time.now - rand(0..(1.year.ago).to_i)).strftime('%Y-%m-%d %H:%M:%S')
    end

    let(:api_public_key) do
      LaunchKey::RSAKey.generate
    end

    let(:config) do
      build(:config).tap do |config|
        config.stub(:api_public_key).and_return(api_public_key)
      end
    end

    let(:keypair) do
      config.keypair
    end

    before do
      app.stub(:call)
      client.stub(:ping)
      client.stub(:api_public_key).and_return(api_public_key)
    end

    context 'when GET request to /v1/ping' do

      let(:env) do
        {
          url:    URI('https://api.launchkey.com/v1/ping'),
          method: :get
        }
      end

      it 'does not sign request' do
        middleware.should_not_receive(:sign_request)
        middleware.call(env)
      end
    end

    context 'when not a ping request' do

      shared_examples_for 'a signed request' do

        it 'keeps existing params' do
          middleware.call(env)
          expect(params).to include(original_params)
        end

        it 'adds app key as string to params' do
          middleware.call(env)
          expect(params[:app_key]).to eq(config.app_key.to_s)
        end

        it 'adds encrypted secret to params' do
          middleware.call(env)

          decrypted_secret = JSON.load api_public_key.private_decrypt(
            Base64.decode64(params[:secret_key])
          )

          expect(decrypted_secret).to eq(
            'secret' => config.secret_key, 'stamped' => ping_timestamp
          )
        end

        it 'adds signature to params' do
          middleware.call(env)

          verified = keypair.verify(
            Base64.decode64(params[:signature]), Base64.decode64(params[:secret_key])
          )

          expect(verified).to be_true
        end
      end

      context 'when GET request' do

        let(:env) do
          {
            url:    URI('https://api.launchkey.com/v1/foo?bar=baz'),
            method: :get
          }
        end

        let(:original_params) do
          { bar: 'baz' }
        end

        let(:params) do
          Rack::Utils.parse_nested_query(env[:url].query).symbolize_keys
        end

        it_behaves_like 'a signed request'
      end

      context 'when non-GET request' do

        let(:env) do
          {
            url:    URI('https://api.launchkey.com/v1/bar'),
            method: :post,
            body:   original_params
          }
        end

        let(:original_params) do
          { some: 'key', another: 'value' }
        end

        let(:params) do
          env[:body]
        end

        it_behaves_like 'a signed request'
      end
    end
  end
end
