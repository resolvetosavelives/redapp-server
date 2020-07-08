class Api::V3::PatientPayloadValidator < Api::V3::PayloadValidator
  attr_accessor(
    :id,
    :full_name,
    :age,
    :gender,
    :date_of_birth,
    :status,
    :age_updated_at,
    :created_at,
    :updated_at,
    :recorded_at,
    :deleted_at,
    :address,
    :phone_numbers,
    :business_identifiers,
    :contacted_by_counsellor,
    :could_not_contact_reason,
    :call_result,
    :reminder_consent,
    :deleted_reason
  )

  validate :validate_schema, unless: -> { FeatureToggle.enabled?("SKIP_API_VALIDATION") }
  validate :presence_of_age
  validate :past_date_of_birth

  def presence_of_age
    unless date_of_birth.present? || (age.present? && age_updated_at.present?)
      errors.add(:age, "Either date_of_birth or age and age_updated_at should be present")
    end
  end

  def past_date_of_birth
    if date_of_birth.present? && date_of_birth.to_s.to_time > Date.current
      errors.add(:date_of_birth, "can't be in the future")
    end
  end

  def schema
    Api::V3::Models.nested_patient
  end
end
