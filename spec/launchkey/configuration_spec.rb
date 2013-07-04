# encoding: utf-8

require 'spec_helper'

describe LaunchKey::Configuration do

  subject(:config) do
    build(:config)
  end

  let(:value) do
    generate(:token)
  end

  [:domain, :app_id, :app_secret, :passphrase].each do |attribute|

    describe "##{attribute}" do

      it 'has getter and setter' do
        config.send(:"#{attribute}=", value)
        expect(config.send(attribute)).to eq(value)
      end
    end
  end

  describe '#initialize' do

    subject(:config) do
      described_class.new(domain: 'example.com', app_id: '12345')
    end

    it 'sets supplied config options' do
      expect(config.domain).to eq('example.com')
      expect(config.app_id).to eq('12345')
    end
  end

  [:update, :merge!].each do |method_name|

    describe "##{method_name}" do

      it 'returns self' do
        expect(config.update({}).object_id).to eq(config.object_id)
      end
    end
  end

  describe '#merge' do

    it 'returns a LaunchKey::Configuration' do
      expect(config.merge({})).to be_a(LaunchKey::Configuration)
    end

    it 'is not the same instance' do
      expect(config.merge({}).object_id).not_to eq(config.object_id)
    end

    it 'sets supplied options' do
      merged = config.merge(domain: 'foo.com', app_id: '123')
      expect(merged.domain).to eq('foo.com')
      expect(merged.app_id).to eq('123')
    end

    context 'when not overridden' do

      it 'keeps original option' do
        merged = config.merge({})
        LaunchKey::Configuration::OPTIONS.each do |option|
          expect(merged.send(option)).to eq(config.send(option))
        end
      end
    end
  end

  describe '#to_hash' do

    it 'returns a Hash' do
      expect(config.to_hash).to be_a(Hash)
    end

    describe 'returned Hash' do

      [:domain, :app_id, :app_secret, :keypair, :passphrase, :endpoint,
       :use_system_ssl_cert_chain, :http_open_timeout, :http_read_timeout,
       :debug].each do |option|

        it "has #{option.inspect}" do
          expect(config.to_hash[option]).to eq(config.send(option))
        end
      end
    end
  end

  describe '#keypair' do

    it 'returns same instance' do
      expect(config.keypair.object_id).to eq(config.keypair.object_id)
    end

    context 'when keypair is not initialized' do

      let(:passphrase) do
        generate(:token)
      end

      let(:raw_keypair) do
        LaunchKey::RSAKey.generate(1024).to_pem(passphrase)
      end

      let(:keypair_double) do
        double(OpenSSL::PKey::RSA, private?: true)
      end

      before do
        config.passphrase = passphrase
        config.keypair    = raw_keypair
      end

      it 'initializes new OpenSSL::PKey::RSA with raw keypair and passphrase' do
        OpenSSL::PKey::RSA.should_receive(:new).with(raw_keypair, passphrase).and_return(keypair_double)
        config.keypair
      end

      it 'returns RSAKey' do
        expect(config.keypair).to be_kind_of(LaunchKey::RSAKey)
      end
    end

    context 'when raw keypair is missing' do

      it 'raises Errors::Misconfiguration' do
        config.keypair = nil
        expect { config.keypair }.to raise_error(LaunchKey::Errors::Misconfiguration)
      end
    end

    context 'when keypair is invalid' do

      it 'raises Errors::InvalidKeypair' do
        config.keypair = 'ಠ_ಠ'
        expect { config.keypair }.to raise_error(LaunchKey::Errors::InvalidKeypair)
      end
    end

    context 'when passphrase is incorrect' do

      it 'raises Errors::PrivateKeyMissing' do
        config.keypair    = LaunchKey::RSAKey.generate(1024).to_pem('top secret')
        config.passphrase = 'secret top'
        expect { config.keypair }.to raise_error(LaunchKey::Errors::PrivateKeyMissing)
      end
    end

    context 'when private key is not present' do

      it 'raises Errors::PrivateKeyMissing' do
        config.keypair = OpenSSL::PKey::RSA.new(1024).public_key.to_pem
        expect { config.keypair }.to raise_error(LaunchKey::Errors::PrivateKeyMissing)
      end
    end
  end

  describe '#keypair=' do

    let(:keypair) do
      OpenSSL::PKey::RSA.new(1024)
    end

    let(:keypair_pem) do
      [keypair.to_pem, keypair.public_key.to_pem].join
    end

    it 'stores supplied value as RSAKey' do
      config.keypair = keypair

      expect(config.keypair).to be_kind_of(LaunchKey::RSAKey)
      expect(config.keypair.to_pem).to eq(keypair_pem)
    end

    context 'when supplied value is RSAKey' do

      let(:keypair) do
        LaunchKey::RSAKey.generate(1024)
      end

      it 'does not reinitialize keypair' do
        config.keypair = keypair
        expect(config.keypair.object_id).to eq(keypair.object_id)
      end
    end
  end

  describe '#api_public_key' do

    it 'returns stored API public key' do
      config.instance_variable_set :@api_public_key, 'bananas'
      expect(config.api_public_key).to eq('bananas')
    end
  end

  describe '#api_public_key=' do

    let(:public_key) do
      generate(:public_key)
    end

    it 'stores supplied value as RSAKey' do
      config.api_public_key = public_key

      expect(config.api_public_key).to be_kind_of(LaunchKey::RSAKey)
      expect(config.api_public_key.to_pem).to eq(public_key)
    end
  end

  describe '#endpoint' do

    let(:config) do
      build(:config)
    end

    subject(:endpoint) do
      config.endpoint
    end

    it 'defaults to https://api.launchkey.com/v1/' do
      expect(endpoint).to eq('https://api.launchkey.com/v1/')
    end
  end

  describe '#validate!' do

    [:domain, :app_id, :app_secret, :keypair].each do |attribute|

      context "when not supplied #{attribute}" do

        let(:attributes) do
          attributes_for(:config)
        end

        subject(:config) do
          attributes.delete attribute
          described_class.new.tap do |config|
            attributes.each do |key, value|
              config.send(:"#{key}=", value)
            end
          end
        end

        it 'raises LaunchKey::Errors::Misconfiguration' do
          expect {
            config.validate!
          }.to raise_error(LaunchKey::Errors::Misconfiguration)
        end
      end
    end
  end

  describe '#middleware' do

    context 'when a block is given' do

      it 'stores supplied block as Proc' do
        block = -> { 'blah blah blah' }
        config.middleware(&block)
        expect(config.middleware).to eq(block)
      end
    end
  end

  describe '#ca_bundle_path' do

    context 'when #use_system_ssl_cert_chain is true' do

      before do
        config.use_system_ssl_cert_chain = true
      end

      context 'when system cert chain exists' do

        before do
          File.stub(:exist?).and_return(true)
        end

        it 'returns OpenSSL::X509::DEFAULT_CERT_FILE' do
          stub_const('OpenSSL::X509::DEFAULT_CERT_FILE', '/usr/local/winning')
          expect(config.ca_bundle_path).to eq(OpenSSL::X509::DEFAULT_CERT_FILE)
        end
      end

      context 'when system cert chain does not exist' do

        before do
          File.stub(:exist?).and_return(false)
        end

        it 'returns #local_cert_path' do
          expect(config.ca_bundle_path).to eq(config.local_cert_path)
        end
      end
    end

    context 'when #use_system_cert_chain is false' do

      it 'returns #local_cert_path' do
      end
    end
  end
end
