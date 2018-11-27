require 'swagger_helper'

describe 'Communication V1 API', swagger_doc: 'v1/swagger.json' do
  path '/communications/sync' do

    post 'Syncs communication data from device to server.' do
      tags 'Communications'
      security [ basic: [] ]
      parameter name: 'HTTP_X_USER_ID', in: :header, type: :uuid
      parameter name: :communications, in: :body, schema: Api::V1::Schema.communication_sync_from_user_request

      response '200', 'communications created' do
        let(:request_user) { FactoryBot.create(:user) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        let(:communications) { { communications: (1..10).map { build_communication_payload } } }

        run_test!
      end

      response '200', 'some, or no errors were found' do
        let(:request_user) { FactoryBot.create(:user) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::V1::Schema.sync_from_user_errors
        let(:communications) { { communications: (1..10).map { build_invalid_communication_payload } } }
        run_test!
      end
    end

    get 'Syncs communication data from server to device.' do
      tags 'Communications'
      security [ basic: [] ]
      parameter name: 'HTTP_X_USER_ID', in: :header, type: :uuid
      Api::V1::Schema.sync_to_user_request.each do |param|
        parameter param
      end

      before :each do
        Timecop.travel(10.minutes.ago) do
          FactoryBot.create_list(:communication, 10)
        end
      end

      response '200', 'communications received' do
        let(:request_user) { FactoryBot.create(:user) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::V1::Schema.communication_sync_to_user_response
        let(:processed_since) { 10.minutes.ago }
        let(:limit) { 10 }
        before do |example|
          submit_request(example.metadata)
        end

        it 'returns a valid 201 response' do |example|
          assert_response_matches_metadata(example.metadata)
        end
      end
    end
  end
end