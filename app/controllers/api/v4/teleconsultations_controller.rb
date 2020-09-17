class Api::V4::TeleconsultationsController < Api::V4::SyncController
  def sync_from_user
    __sync_from_user__(teleconsultation_params)
  end

  private

  def merge_if_valid(teleconsultation_params)
    validator = Api::V4::TeleconsultationPayloadValidator.new(teleconsultation_params)
    logger.debug "Teleconsultation had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric("Merge/Teleconsultation/schema_invalid")
      {errors_hash: validator.errors_hash}
    else
      transformed_params = Api::V4::TeleconsultationTransformer.from_request(
        teleconsultation_params,
        retrieve_record: current_user.can_teleconsult?
      )

      teleconsultation = Teleconsultation.merge(transformed_params)
      {record: teleconsultation}
    end
  end

  def teleconsultation_params
    params.require(:teleconsultations).map do |teleconsultation_params|
      teleconsultation_params.permit(
        :id,
        :patient_id,
        :medical_officer_id,
        :request,
        :updated_at,
        :deleted_at,
        :created_at,
        request: Teleconsultation::REQUEST_ATTRIBUTES,
        record: Teleconsultation::RECORD_ATTRIBUTES
      )
    end
  end
end
