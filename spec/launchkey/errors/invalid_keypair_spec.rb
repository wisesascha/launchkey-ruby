require 'spec_helper'

describe LaunchKey::Errors::InvalidKeypair do

  let(:original_exception) do
    double(OpenSSL::PKey::RSAError)
  end

  let(:error) do
    described_class.new(original_exception)
  end

  subject(:message) do
    error.message
  end

  it 'contains the problem in the message' do
    expect(message).to include(
      'RSA keypair is invalid or malformed'
    )
  end

  it 'contains the original exception in the message' do
    original_exception.should_receive(:to_s).and_return('Something went terribly wrong.')
    expect(message).to include(
      'Something went terribly wrong.'
    )
  end

  it 'contains the summary in the message' do
    expect(message).to include(
      'valid keypair is required'
    )
  end

  it 'contains the resolution in the message' do
    expect(message).to include(
      'Check that a valid keypair has been set'
    )
  end
end
