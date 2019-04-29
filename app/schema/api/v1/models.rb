class Api::V1::Models < Api::V2::Models
  class << self
    def medical_history
      { type: :object,
        properties: {
          id: { '$ref' => '#/definitions/uuid' },
          patient_id: { '$ref' => '#/definitions/uuid' },
          prior_heart_attack: { type: :boolean },
          prior_stroke: { type: :boolean },
          chronic_kidney_disease: { type: :boolean },
          receiving_treatment_for_hypertension: { type: :boolean },
          diabetes: { type: :boolean },
          diagnosed_with_hypertension: { type: :boolean },
          created_at: { '$ref' => '#/definitions/timestamp' },
          updated_at: { '$ref' => '#/definitions/timestamp' } },
        required: [
          :id,
          :patient_id,
          :prior_heart_attack,
          :prior_stroke,
          :chronic_kidney_disease,
          :receiving_treatment_for_hypertension,
          :diabetes,
          :created_at,
          :updated_at
        ]
      }
    end

    def user
      { type: :object,
        properties: {
          id: { '$ref' => '#/definitions/uuid' },
          created_at: { '$ref' => '#/definitions/timestamp' },
          updated_at: { '$ref' => '#/definitions/timestamp' },
          full_name: { '$ref' => '#/definitions/non_empty_string' },
          phone_number: { '$ref' => '#/definitions/non_empty_string' },
          password_digest: { '$ref' => '#/definitions/bcrypt_password' },
          facility_ids: array_of(:uuid),
        },
        required: %w[id created_at updated_at full_name phone_number password_digest facility_ids] }
    end

    def patient
      super.tap { |d| d[:properties].delete(:deleted_at) }
    end

    def nested_patient
      super.tap { |d| d[:properties].delete(:deleted_at) }
    end

    def address
      super.tap { |d| d[:properties].delete(:deleted_at) }
    end

    def phone_number
      super.tap { |d| d[:properties].delete(:deleted_at) }
    end

    def blood_pressure
      super.tap { |d| d[:properties].delete(:deleted_at) }
    end

    def facility
      super.tap { |d| d[:properties].delete(:deleted_at) }
    end

    def protocol_drug
      super.tap { |d| d[:properties].delete(:deleted_at) }
    end

    def protocol
      super.tap { |d| d[:properties].delete(:deleted_at) }
    end

    def prescription_drug
      super.tap { |d| d[:properties].delete(:deleted_at) }
    end

    def appointment
      super
        .tap { |d| d[:properties].delete(:deleted_at) }
        .tap { |d| d[:properties][:cancel_reason][:enum] -= %w(invalid_phone_number public_hospital_transfer moved_to_private) }
    end

    def communication
      super.tap { |d| d[:properties].delete(:deleted_at) }
    end

    def definitions
      super.merge(
        medical_history: medical_history,
        patient: patient,
        nested_patient: nested_patient,
        address: address,
        phone_number: phone_number,
        blood_pressure: blood_pressure,
        facility: facility,
        protocol_drug: protocol_drug,
        protocol: protocol,
        prescription_drug: prescription_drug,
        user: user,
        appointment: appointment,
        communication: communication
      )
    end
  end
end