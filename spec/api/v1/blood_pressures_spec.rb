require 'swagger_helper'

describe 'BloodPressures V1 API', swagger_doc: 'v1/swagger.json' do
  path '/blood_pressures/sync' do

    post 'Syncs blood pressure data from device to server.' do
      tags 'Blood Pressure'
      security [ basic: [] ]
      parameter name: 'HTTP_X_USER_ID', in: :header, type: :uuid
      parameter name: :blood_pressures, in: :body, schema: Api::V1::Schema.blood_pressure_sync_from_user_request

      response '200', 'blood pressures created' do
        let(:request_user) { FactoryBot.create(:user) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        let(:blood_pressures) { { blood_pressures: (1..10).map { build_blood_pressure_payload } } }

        run_test!
      end

      response '200', 'some, or no errors were found' do
        let(:request_user) { FactoryBot.create(:user) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::V1::Schema.sync_from_user_errors
        let(:blood_pressures) { { blood_pressures: (1..10).map { build_invalid_blood_pressure_payload } } }
        run_test!
      end
    end

    get 'Syncs blood pressure data from server to device.' do
      tags 'Blood Pressure'
      security [ basic: [] ]
      parameter name: 'HTTP_X_USER_ID', in: :header, type: :uuid
      Api::V1::Schema.sync_to_user_request.each do |param|
        parameter param
      end

      before :each do
        Timecop.travel(10.minutes.ago) do
          FactoryBot.create_list(:blood_pressure, 10)
        end
      end

      response '200', 'blood pressures received' do
        let(:request_user) { FactoryBot.create(:user) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::V1::Schema.blood_pressure_sync_to_user_response
        let(:processed_since) { 10.minutes.ago }
        let(:limit) { 10 }
        run_test!
      end
    end
  end
end