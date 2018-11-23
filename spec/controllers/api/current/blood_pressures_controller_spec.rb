require 'rails_helper'

RSpec.describe Api::Current::BloodPressuresController, type: :controller do
  let(:request_user) { FactoryBot.create(:user) }
  let(:request_facility) { FactoryBot.create(:facility) }
  before :each do
    request.env['X_USER_ID'] = request_user.id
    request.env['X_FACILITY_ID'] = request_facility.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  let(:model) { BloodPressure }

  let(:build_payload) { lambda { build_blood_pressure_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_blood_pressure_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { lambda { |blood_pressure| updated_blood_pressure_payload blood_pressure } }
  let(:number_of_schema_errors_in_invalid_payload) { 3 }

  it_behaves_like 'a sync controller that authenticates user requests'
  it_behaves_like 'a sync controller that audits the data access'
  it_behaves_like 'a working sync controller that short circuits disabled apis'

  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'a working sync controller creating records'
    it_behaves_like 'a working sync controller updating records'

    describe 'creates new blood pressures' do
      before :each do
        request.env['HTTP_X_USER_ID'] = request_user.id
        request.env['HTTP_X_FACILITY_ID'] = request_facility.id
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
      end

      it 'creates new blood pressures with associated patient' do
        patient = FactoryBot.create(:patient)
        blood_pressures = (1..10).map do
          build_blood_pressure_payload(FactoryBot.build(:blood_pressure, patient: patient))
        end
        post(:sync_from_user, params: { blood_pressures: blood_pressures }, as: :json)
        expect(BloodPressure.count).to eq 10
        expect(patient.blood_pressures.count).to eq 10
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working Current sync controller sending records'

    describe 'current facility prioritisation' do
      it "syncs request facility's records first" do
        request_2_facility = FactoryBot.create(:facility)
        FactoryBot.create_list(:blood_pressure, 5, facility: request_facility, updated_at: 3.minutes.ago)
        FactoryBot.create_list(:blood_pressure, 5, facility: request_facility, updated_at: 5.minutes.ago)
        FactoryBot.create_list(:blood_pressure, 5, facility: request_2_facility, updated_at: 7.minutes.ago)
        FactoryBot.create_list(:blood_pressure, 5, facility: request_2_facility, updated_at: 10.minutes.ago)

        # GET request 1
        set_authentication_headers
        get :sync_to_user, params: { limit: 10 }
        response_1_body = JSON(response.body)

        record_ids = response_1_body['blood_pressures'].map { |r| r['id'] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 10
        expect(records.map(&:facility).to_set).to eq Set[request_facility]

        # GET request 2
        get :sync_to_user, params: { limit: 10, process_token: response_1_body['process_token'] }
        response_2_body = JSON(response.body)

        record_ids = response_2_body['blood_pressures'].map { |r| r['id'] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 10
        expect(records.map(&:facility).to_set).to eq Set[request_facility, request_2_facility]
      end
    end
  end
end
