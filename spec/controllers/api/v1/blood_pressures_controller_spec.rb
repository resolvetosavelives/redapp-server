require 'rails_helper'

RSpec.describe Api::V1::BloodPressuresController, type: :controller do
  let(:request_user) { FactoryBot.create(:user) }
  before :each do
    request.env['X_USER_ID'] = request_user.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  let(:model) { BloodPressure }

  let(:build_payload) { lambda { build_blood_pressure_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_blood_pressure_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { lambda { |blood_pressure| updated_blood_pressure_payload blood_pressure } }
  let(:number_of_schema_errors_in_invalid_payload) { 3 }

  def create_record(options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    FactoryBot.create(:blood_pressure, options.merge(facility: facility))
  end

  def create_record_list(n, options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    FactoryBot.create_list(:blood_pressure, n, options.merge(facility: facility))
  end

  it_behaves_like 'a sync controller that authenticates user requests'
  it_behaves_like 'a sync controller that audits the data access'
  it_behaves_like 'a working sync controller that short circuits disabled apis'

  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'a working sync controller creating records'
    it_behaves_like 'a working sync controller updating records'

    describe 'creates new blood pressures' do
      before :each do
        request.env['HTTP_X_USER_ID'] = request_user.id
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
    it_behaves_like 'a working V1 sync controller sending records'
  end

  describe 'syncing within a facility group' do
    let(:facility_in_same_group) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
    let(:facility_in_another_group) { FactoryBot.create(:facility) }

    before :each do
      set_authentication_headers
      FactoryBot.create_list(:blood_pressure, 5, facility: facility_in_another_group, updated_at: 3.minutes.ago)
      FactoryBot.create_list(:blood_pressure, 5, facility: facility_in_same_group, updated_at: 5.minutes.ago)
    end

    it "only sends data for facilities belonging in the sync group of user's registration facility" do
      get :sync_to_user, params: { limit: 15 }

      response_blood_pressures = JSON(response.body)['blood_pressures']
      response_facilities = response_blood_pressures.map { |blood_pressure| blood_pressure['facility_id']}.to_set

      expect(response_blood_pressures.count).to eq 5
      expect(response_facilities).not_to include(facility_in_another_group.id)
    end
  end
end
