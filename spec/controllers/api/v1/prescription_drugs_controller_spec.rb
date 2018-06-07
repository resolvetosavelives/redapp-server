require 'rails_helper'

RSpec.describe Api::V1::PrescriptionDrugsController, type: :controller do
  let(:model) { PrescriptionDrug }

  let(:build_payload) { lambda { build_prescription_drug_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_prescription_drug_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { lambda { |prescription_drug| updated_prescription_drug_payload prescription_drug } }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }

  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'a working sync controller creating records'
    it_behaves_like 'a working sync controller updating records'

    describe 'creates new prescription drugs' do
      it 'creates new prescription drugs with associated patient' do
        patient = FactoryBot.create(:patient)
        prescription_drugs = (1..10).map do
          build_prescription_drug_payload(FactoryBot.build(:prescription_drug, patient: patient))
        end
        post(:sync_from_user, params: { prescription_drugs: prescription_drugs }, as: :json)
        expect(PrescriptionDrug.count).to eq 10
        expect(patient.prescription_drugs.count).to eq 10
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working sync controller sending records'
  end
end
