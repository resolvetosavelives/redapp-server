require 'rails_helper'

RSpec.describe 'Patients sync', type: :request do
  let(:sync_route) { '/api/v1/patients/sync' }
  let(:headers) { { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' } }

  let(:response_key) { 'patients' }
  let(:empty_payload) { { patients: [] } }
  let(:valid_payload) { { patients: [build_patient_payload] } }
  let(:model) { Patient }
  let(:expected_response) do
    valid_payload[:patients].map do |patient|
      patient.with_int_timestamps.to_json_and_back
    end
  end

  let(:created_records) { (1..10).map { build_patient_payload } }
  let(:many_valid_records) { { patients: created_records } }
  let(:updated_records) do
    Patient
      .find(created_records.map { |record| record['id'] })
      .take(5)
      .map { |record| updated_patient_payload record }
  end
  let(:updated_payload) { { patients: updated_records } }

  def to_response(patient)
    Api::V1::PatientTransformer.to_nested_response(patient)
  end

  include_examples 'sync requests'


  def assert_sync_success(response, processed_since)
    received_patients = JSON(response.body)['patients']

    expect(response.status).to eq 200
    expect(received_patients.count)
      .to eq Patient.updated_on_server_since(processed_since.to_time).count

    expect(received_patients
             .map { |patient_response| patient_response.with_int_timestamps }
             .to_set)
      .to eq Patient.updated_on_server_since(processed_since.to_time)
               .map { |patient| Api::V1::PatientTransformer.to_nested_response(patient).with_int_timestamps }
               .to_set
  end

  it 'pushes 10 new patients, updates only address or phone numbers, and pulls updated ones' do
    first_patients_payload = (1..10).map { build_patient_payload }
    post sync_route, params: { patients: first_patients_payload }.to_json, headers: headers
    get sync_route, params: {}, headers: headers
    processed_since = JSON(response.body)['processed_since']

    created_patients         = Patient.find(first_patients_payload.map { |patient| patient['id'] })
    updated_patients_payload = created_patients.map do |patient|
      updated_patient_payload(patient)
        .except(%w(address phone_numbers).sample)
    end

    post sync_route, params: { patients: updated_patients_payload }.to_json, headers: headers
    get sync_route, params: { processed_since: processed_since }, headers: headers

    assert_sync_success(response, processed_since)
  end
end
