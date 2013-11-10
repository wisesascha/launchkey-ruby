require 'spec_helper'

describe LaunchKey::Middleware::RaiseErrors do

  let(:app) do
    ->(env){ Faraday::Response.new(env) }
  end

  subject(:middleware) do
    described_class.new(app)
  end

  shared_examples_for 'an unsuccessful response' do

    context 'when body contains message and code' do

      let(:env) do
        {
          status: status, body: body
        }
      end

      it 'raises APIError with message and code' do
        error = nil

        begin
          middleware.call(env)
        rescue LaunchKey::Errors::APIError
          error = $!
        end

        expect(error.message).to eq(body['message'])
        expect(error.code).to eq(body['message_code'])
      end

      it 'stores response in raised error' do
        mock_response = Faraday::Response.new(env)
        app.stub(:call).and_return(mock_response)
        error = nil

        begin
          middleware.call(env)
        rescue LaunchKey::Errors::APIError
          error = $!
        end

        expect(error.response.object_id).to eq(
          mock_response.object_id
        )
      end
    end

  end

  describe '#call' do

    context 'when non-success body' do

      let(:status) do
        200
      end

      let(:body) do
        {
          'message'      => 'Incorrect data for API call',
          'message_code' => 60401,
          'successful'   => false
        }
      end

      it_should_behave_like 'an unsuccessful response'
    end

    context 'when non-success status' do

      let(:status) do
        401
      end

      let(:body) do
        {
          'message'      => 'Invalid app key',
          'message_code' => 40425
        }
      end

      it_should_behave_like 'an unsuccessful response'

      context 'when body is empty' do

        let(:env) do
          {
            status: 400, body: nil
          }
        end

        it 'raises generic APIError' do
          expect {
            middleware.call(env)
          }.to raise_error(LaunchKey::Errors::APIError, 'Unknown error')
        end
      end
    end
  end
end
