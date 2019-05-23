class Api::Current::PatientsController < Api::Current::SyncController
  def sync_from_user
    __sync_from_user__(patients_params)
  end

  def sync_to_user
    __sync_to_user__('patients')
  end

  def metadata
    { registration_user_id: current_user.id,
      registration_facility_id: current_facility.id }
  end

  def current_facility_records
    facility_group_records
      .includes(:address, :phone_numbers)
      .where(registration_facility: current_facility)
      .updated_on_server_since(current_facility_processed_since, limit)
  end

  def other_facility_records
    other_facilities_limit = limit - current_facility_records.count
    facility_group_records
      .includes(:address, :phone_numbers)
      .where.not(registration_facility: current_facility.id)
      .updated_on_server_since(other_facilities_processed_since, other_facilities_limit)
  end

  private

  def merge_if_valid(single_patient_params)
    validator = Api::Current::PatientPayloadValidator.new(single_patient_params)
    logger.debug "Patient had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/Patient/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      patients_params_with_metadata = single_patient_params.merge(metadata: metadata)
      patient = MergePatientService.new(
        set_default_recorded_at(Api::Current::PatientTransformer.from_nested_request(patients_params_with_metadata))
      ).merge
      { record: patient }
    end
  end

  def set_default_recorded_at(patient_params)
    patient_params.merge('recorded_at' => default_recorded_at(patient_params))
  end

  def default_recorded_at(patient_params)
    return patient_params['recorded_at'] if patient_params['recorded_at'].present?

    patient_recorded_at = patient_params['device_created_at']
    earliest_blood_pressure = BloodPressure
                                .where(patient_id: patient_params['id'])
                                .order(recorded_at: :asc)
                                .first

    earliest_blood_pressure.blank? ?
      patient_recorded_at : [patient_recorded_at, earliest_blood_pressure.recorded_at].min
  end

  def transform_to_response(patient)
    Api::Current::PatientTransformer.to_nested_response(patient)
  end

  def patients_params
    permitted_address_params = %i[id street_address village_or_colony district state country pin created_at updated_at]
    permitted_phone_number_params = %i[id number phone_type active created_at updated_at]
    permitted_business_identifier_params = %i[id identifier identifier_type metadata metadata_version created_at updated_at]

    patient_attributes = params.require(:patients)
    patient_attributes.map do |single_patient_params|
      single_patient_params.permit(
        :id,
        :full_name,
        :age,
        :age_updated_at,
        :gender,
        :status,
        :date_of_birth,
        :created_at,
        :updated_at,
        :recorded_at,
        phone_numbers: [permitted_phone_number_params],
        address: permitted_address_params,
        business_identifiers: [permitted_business_identifier_params]
      )
    end
  end
end
