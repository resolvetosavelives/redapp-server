require 'rails_helper'

RSpec.describe 'PrescriptionDrugs sync', type: :request do
  let(:sync_route) { '/api/v1/prescription_drugs/sync' }

  let(:model) { PrescriptionDrug }

  let(:build_payload) { lambda { build_prescription_drug_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_prescription_drug_payload } }
  let(:update_payload) { lambda { |prescription_drug| updated_prescription_drug_payload prescription_drug } }

  def to_response(prescription_drug)
    Api::V1::Transformer.to_response(prescription_drug)
  end

  include_examples 'sync requests'
end
