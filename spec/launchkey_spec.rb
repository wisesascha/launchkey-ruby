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

      it 'delegates to .config' do
        described_class.config.should_receive(method)
        described_class.send(method)
      end
    end
  end
end
