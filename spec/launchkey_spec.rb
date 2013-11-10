require 'spec_helper'

describe LaunchKey do

  describe '.configure' do

    it 'yields the config singleton' do
      expect { |block| described_class.configure(&block) }.to yield_with_args(described_class.config)
    end
  end

  describe '.config' do

    it 'returns an instance of LaunchKey::Configuration' do
      expect(described_class.config).to be_a(LaunchKey::Configuration)
    end

    it 'returns the same instance' do
      expect(described_class.config.object_id).to eq(described_class.config.object_id)
    end
  end

  LaunchKey::Configuration.public_instance_methods(false).each do |method|

    describe ".#{method}" do

      let(:config) do
        double(LaunchKey::Configuration)
      end

      before do
        described_class.stub(:config).and_return(config)
      end

      it 'delegates to .config' do
        config.should_receive(method).with('foo')
        described_class.send(method, 'foo')
      end
    end
  end

  (LaunchKey::Client.public_instance_methods(false) - [:config]).each do |method|

    describe ".#{method}" do

      let(:client) do
        double(LaunchKey::Client)
      end

      before do
        described_class.stub(:client).and_return(client)
      end

      it 'delegates to .client' do
        client.should_receive(method).with(anything)
        described_class.send(method, 'foo')
      end
    end
  end
end
