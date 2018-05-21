module Spec

  ###############
  # Models

  def patient_spec
    { type:       :object,
      properties: {
        id:               { type: :string, format: :uuid },
        gender:           { type: :string, enum: Patient::GENDERS },
        full_name:        { type: :string },
        status:           { type: :string, enum: Patient::STATUSES },
        date_of_birth:    { type: [:string, 'null'], format: :date },
        age_when_created: { type: [:integer, 'null'] },
        created_at:       { type: :string, format: 'date-time' },
        updated_at:       { type: :string, format: 'date-time' } },
      required:   %w[id gender full_name created_at updated_at status] }
  end

  def address_spec
    { type:       :object,
      properties: {
        id:             { type: :string, format: :uuid },
        street_address: { type: :string },
        colony:         { type: :string },
        village:        { type: :string },
        district:       { type: :string },
        state:          { type: :string },
        country:        { type: :string },
        pin:            { type: :string },
        created_at:     { type: :string, format: 'date-time' },
        updated_at:     { type: :string, format: 'date-time' } },
      required:   %w[id created_at updated_at] }
  end

  def phone_number_spec
    { type:       :object,
      properties: {
        id:         { type: :string, format: :uuid },
        number:     { type: :string },
        phone_type: { type: :string, enum: PhoneNumber::PHONE_TYPE },
        active:     { type: :boolean },
        created_at: { type: :string, format: 'date-time' },
        updated_at: { type: :string, format: 'date-time' } },
      required:   %w[id created_at updated_at] }
  end


  ###############
  # API Specs

  def phone_numbers_spec
    { type:  :array,
      items: { '$ref' => '#/definitions/phone_number' } }
  end

  def nested_patients
    { type:  :array,
      description: 'List of patients with address and phone numbers nested.',
      items: patient_spec.deep_merge(
        properties: {
          address:       { '$ref' => '#/definitions/address' },
          phone_numbers: { '$ref' => '#/definitions/phone_numbers' } }
      ) }
  end

  def error_spec
    { type:       :object,
      properties: {
        id:               { type: :string, format: :uuid },
        field_with_error: { type:  :array,
                            items: { type: :string } } },
      required:   %w[id] }
  end

  def patient_error_spec
    { type:       :object,
      properties: {
        id:            { type: :string, format: :uuid },
        address:       { '$ref' => '#/definitions/error_spec' },
        phone_numbers: { type:  :array,
                         items: { '$ref' => '#/definitions/error_spec' } } },
      required:   %w[id] }
  end

  def patient_sync_from_user_errors_spec
    { type:       :object,
      properties: {
        errors: {
          type:  :array,
          items: { '$ref' => '#/definitions/patient_error_spec' } } } }
  end

  def patient_sync_to_user_request_spec
    [{ in:          :query, name: :latest_record_timestamp, type: :string, format: 'date-time',
       description: 'Timestamp of the latest record synced with server.' },
     { in:          :query, name: :first_time, type: :boolean,
       description: 'Set to true only when syncing for the first time' },
     { in:          :query, name: :number_of_records, type: :integer,
       description: 'Number of record to retrieve (a.k.a batch-size)' }]
  end

  def patient_sync_from_user_request_spec
    { type:       :object,
      properties: {
        patients: { '$ref' => '#/definitions/nested_patients' } },
      required:   %w[patients] }
  end

  def patient_sync_to_user_response_spec
    { type:       :object,
      properties: {
        patients:                { '$ref' => '#/definitions/nested_patients' },
        latest_record_timestamp: {
          type:        :string,
          format:      'date-time',
          description: 'Use this in the next request to continue fetching records.' } } }
  end

  def all_definitions
    { patient:            patient_spec,
      address:            address_spec,
      phone_number:       phone_number_spec,
      phone_numbers:      phone_numbers_spec,
      error_spec:         error_spec,
      patient_error_spec: patient_error_spec,
      nested_patients:    nested_patients }
  end

end