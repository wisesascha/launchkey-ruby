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

  [:keypair, :api_public_key].each do |attribute|

    describe "##{attribute}" do

      it 'has getter' do
        config.instance_variable_set :"@#{attribute}", 'foo'
        expect(config.send(attribute)).to eq('foo')
      end
    end
  end

  describe '#keypair=' do

    let(:keypair) do
      OpenSSL::PKey::RSA.new(1024)
    end

    let(:keypair_array) do
      [keypair.to_pem, keypair.public_key.to_pem]
    end

    it 'stores supplied value as OpenSSL::PKey::RSA' do
      config.keypair = keypair_array.join

      expect(config.keypair).to be_kind_of(OpenSSL::PKey::RSA)
      expect(
        [config.keypair.to_pem, config.keypair.public_key.to_pem]
      ).to eq(keypair_array)
    end
  end

  describe '#api_public_key=' do

    let(:public_key) do
      generate(:public_key)
    end

    it 'stores supplied value as OpenSSL::PKey::RSA' do
      config.api_public_key = public_key

      expect(config.api_public_key).to be_kind_of(OpenSSL::PKey::RSA)
      expect(config.api_public_key.to_pem).to eq(public_key)
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
end
