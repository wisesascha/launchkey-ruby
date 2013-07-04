require 'spec_helper'

describe LaunchKey::Errors::PrivateKeyMissing do

  let(:error) do
    described_class.new
  end

  subject(:message) do
    error.message
  end

  it 'contains the problem in the message' do
    expect(message).to include(
      'RSA keypair is missing a private key'
    )
  end

  it 'contains the summary in the message' do
    expect(message).to include(
      'private key is required'
    )
  end

  it 'contains the resolution in the message' do
    expect(message).to include(
      'Check that a valid keypair and passphrase have been set'
    )
  end
end
