require 'spec_helper'

describe LaunchKey::Errors::Misconfiguration do

  let(:error) do
    described_class.new
  end

  subject(:message) do
    error.message
  end

  it 'contains the problem in the message' do
    expect(message).to include(
      'LaunchKey has not been fully configured.'
    )
  end

  it 'contains the summary in the message' do
    expect(message).to include(
      'A domain, application ID, secret, and private key are required.'
    )
  end

  it 'contains the resolution in the message' do
    expect(message).to include(
      'Check the documentation'
    )
  end
end
