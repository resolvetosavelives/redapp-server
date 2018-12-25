require 'rails_helper'

RSpec.describe 'PrescriptionDrugs sync', type: :request do
  let(:sync_route) { '/api/v2/prescription_drugs/sync' }
  let(:request_user) { FactoryBot.create(:user) }

  let(:model) { PrescriptionDrug }

  let(:build_payload) { lambda { build_prescription_drug_payload(FactoryBot.build(:prescription_drug, facility: request_user.facility)) } }
  let(:build_invalid_payload) { lambda { build_invalid_prescription_drug_payload } }
  let(:update_payload) { lambda { |prescription_drug| updated_prescription_drug_payload prescription_drug } }

  def to_response(prescription_drug)
    Api::Current::Transformer.to_response(prescription_drug)
  end

  include_examples 'current API sync requests'
end
