require 'spec_helper'

describe LaunchKey::Errors::APIError do

  let(:response_message) do
    'The server broke'
  end

  let(:message_code) do
    1337
  end

  let(:response) do
    double(Faraday::Response, status: 418)
  end

  let(:error) do
    described_class.new(response_message, message_code, response)
  end

  subject(:message) do
    error.to_s
  end

  it 'contains the problem in the message' do
    expect(message).to include(
      'The server broke'
    )
  end

  it 'contains the message code in the message' do
    expect(message).to include(
      '[1337]'
    )
  end

  it 'contains the HTTP response status in the message' do
    expect(message).to include(
      '(Status 418)'
    )
  end
end
