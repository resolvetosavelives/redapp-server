class MergePatientService

  def initialize(payload)
    @payload = payload
  end

  def merge
    merged_address = Address.merge(payload[:address])
    merged_phone_numbers = merge_phone_numbers(payload[:phone_numbers])

    patient_attributes = payload.except(:address, :phone_numbers)
    patient_attributes['address_id'] = merged_address.id if merged_address.present?
    merged_patient = Patient.merge(patient_attributes)
    merged_patient.address = merged_address

    if (merged_address.present? && merged_address.merged?) || merged_phone_numbers.any?(&:merged?)
      merged_patient.update_column(:updated_on_server_at, Time.now)
    end

    merged_patient
  end

  private

  attr_reader :payload

  def merge_phone_numbers(phone_number_params)
    return [] unless phone_number_params.present?
    phone_number_params.map do |single_phone_number_params|
      PhoneNumber.merge(single_phone_number_params)
    end
  end
end