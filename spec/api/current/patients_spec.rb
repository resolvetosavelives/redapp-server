require 'swagger_helper'

describe 'Patients Current API', swagger_doc: 'current/swagger.json' do
  path '/patients/sync' do

    post 'Syncs patient, address and phone number data from device to server.' do
      tags 'patient'
      security [ basic: [] ]
      parameter name: 'HTTP_X_USER_ID', in: :header, type: :uuid
      parameter name: 'HTTP_X_FACILITY_ID', in: :header, type: :uuid
      parameter name: :patients, in: :body, schema: Api::Current::Schema.patient_sync_from_user_request

      response '200', 'patients created' do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        let(:patients) { { patients: (1..10).map { build_patient_payload } } }
        run_test!
      end

      response '200', 'some, or no errors were found' do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::Current::Schema.sync_from_user_errors
        let(:patients) { { patients: (1..10).map { build_invalid_patient_payload } } }
        run_test!
      end
    end

    get 'Syncs patient, address and phone number data from server to device.' do
      tags 'patient'
      security [ basic: [] ]
      parameter name: 'HTTP_X_USER_ID', in: :header, type: :uuid
      parameter name: 'HTTP_X_FACILITY_ID', in: :header, type: :uuid
      Api::Current::Schema.sync_to_user_request.each do |param|
        parameter param
      end

      before :each do
        Timecop.travel(10.minutes.ago) do
          FactoryBot.create_list(:patient, 10)
        end
      end

      response '200', 'patients received' do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::Current::Schema.patient_sync_to_user_response
        let(:processed_since) { 10.minutes.ago }
        let(:limit) { 10 }
        run_test!
      end
    end
  end
end
