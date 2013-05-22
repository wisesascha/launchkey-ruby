require 'spec_helper'

describe LaunchKey::Configuration do

  subject(:config) do
    build(:config)
  end

  let(:value) do
    generate(:token)
  end

  [:domain, :app_id, :app_secret, :private_key, :passphrase].each do |attribute|

    describe "##{attribute}" do

      it 'has getter and setter' do
        config.send(:"#{attribute}=", value)
        expect(config.send(attribute)).to eq(value)
      end
    end
  end

  describe '#validate!' do

    context 'when not supplied passphrase' do

      subject(:config) do
        build(:config, passphrase: nil)
      end

      it 'does not raise errors' do
        expect { config.validate! }.not_to raise_error
      end
    end

    [:domain, :app_id, :app_secret, :private_key].each do |attribute|

      context "when not supplied #{attribute}" do

        subject(:config) do
          build(:config, attribute => nil)
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
