class Api::Current::BloodPressuresController < Api::Current::SyncController
  include Api::Current::PrioritisableByFacility
  include Api::Current::SyncEncounterObservation
  include Api::Current::RetroactiveDataEntry

  def sync_from_user
    __sync_from_user__(blood_pressures_params)
  end

  def sync_to_user
    __sync_to_user__('blood_pressures')
  end

  private

  def merge_if_valid(bp_params)
    validator = Api::Current::BloodPressurePayloadValidator.new(bp_params)
    logger.debug "Blood Pressure had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/BloodPressure/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      set_patient_recorded_at(bp_params)
      transformed_params = Api::Current::BloodPressureTransformer.from_request(bp_params)
      { record: merge_encounter_observation(:blood_pressures, transformed_params) }
    end
  end

  def transform_to_response(blood_pressure)
    Api::Current::Transformer.to_response(blood_pressure)
  end

  def blood_pressures_params
    params.require(:blood_pressures).map do |blood_pressure_params|
      blood_pressure_params.permit(
        :id,
        :systolic,
        :diastolic,
        :patient_id,
        :facility_id,
        :user_id,
        :created_at,
        :updated_at,
        :recorded_at,
        :deleted_at
      )
    end
  end
end
