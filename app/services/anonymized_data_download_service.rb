require 'csv'

class AnonymizedDataDownloadService
  def initialize(recipient_name, recipient_email, recipient_role, entity_map, entity_type)
    @recipient_name = recipient_name
    @recipient_email = recipient_email
    @recipient_role = recipient_role
    @entity_map = entity_map
    @entity_type = entity_type
  end

  def execute
    begin
      anonymized_data = anonymize_data

      AnonymizedDataDownloadMailer
        .with(recipient_name: @recipient_name,
              recipient_email: @recipient_email,
              recipient_role: @recipient_role,
              anonymized_data: anonymized_data)
        .mail_anonymized_data
        .deliver_later
    rescue StandardError => e
      puts "Caught error: #{e.inspect}"
    end
  end

  private

  def anonymize_data
    case @entity_type
    when 'district'
      anonymize_district_data
    when 'facility'
      anonymize_facility_data
    else
      raise "Error: Unknown entity type: #{entity_type}"
    end
  end

  def anonymize_district_data
    organization_district = OrganizationDistrict.new(@entity_map[:district_name], Organization.find(@entity_map[:organization_id]))
    organization_district_patients = organization_district.facilities.flat_map(&:patients)

    anonymize(organization_district_patients)
  end

  def anonymize_facility_data
    facility = Facility.find(@entity_map[:facility_id])
    facility_patients = facility.patients

    anonymize(facility_patients)
  end

  def anonymize(patients)
    csv_data = Hash.new

    patients_csv_file = CSVGeneration::patients_csv(patients)
    csv_data[AnonymizedDataConstants::PATIENTS_FILE] = patients_csv_file

    blood_pressures = patients.flat_map(&:blood_pressures)
    bps_csv_file = CSVGeneration::bps_csv(blood_pressures)
    csv_data[AnonymizedDataConstants::BPS_FILE] = bps_csv_file

    prescriptions = patients.flat_map(&:prescription_drugs)
    meds_csv_file = CSVGeneration::medicines_csv(prescriptions)
    csv_data[AnonymizedDataConstants::MEDICINES_FILE] = meds_csv_file

    appointments = patients.flat_map(&:appointments)
    appointments_csv_file = CSVGeneration::appointments_csv(appointments)
    csv_data[AnonymizedDataConstants::APPOINTMENTS_FILE] = appointments_csv_file

    all_overdue_appointments = Appointment.overdue
    all_patient_ids = patients.map(&:id)
    overdue_appointments = all_overdue_appointments.select do |overdue_appointment|
      all_patient_ids.include?(overdue_appointment.id)
    end

    overdue_appointments_csv_file = CSVGeneration::overdue_csv(overdue_appointments)
    csv_data[AnonymizedDataConstants::OVERDUES_FILE] = overdue_appointments_csv_file

    communications_for_facility = appointments.flat_map(&:communications)
    communications_csv_file = CSVGeneration::communications_csv(communications_for_facility)
    csv_data[AnonymizedDataConstants::COMMUNICATIONS_FILE] = communications_csv_file

    csv_data

  end

  module CSVGeneration
    UNAVAILABLE = 'Unavailable'

    def self.hash_uuid(original_uuid)
      UUIDTools::UUID.md5_create(UUIDTools::UUID_DNS_NAMESPACE, { uuid: original_uuid }.to_s).to_s
    end

    def self.patients_csv(patients)
      CSV.generate(headers: true) do |csv|
        csv << AnonymizedDataConstants.patient_headers.map(&:titleize)

        patients.each do |patient|
          user_id = User.where(id: patient.registration_user_id).first
          facility_name = Facility.where(id: patient.registration_facility_id).first&.name

          csv << [
            hash_uuid(patient.id),
            patient.created_at,
            patient.recorded_at,
            original_else_blank_value(facility_name),
            hashed_else_blank_value(user_id),
            patient.age,
            patient.gender
          ]
        end
      end
    end

    def self.bps_csv(blood_pressures)
      CSV.generate(headers: true) do |csv|
        csv << AnonymizedDataConstants.bp_headers.map(&:titleize)

        blood_pressures.each do |bp|
          user_id = User.where(id: bp.user_id).first
          facility_name = Facility.where(id: bp.facility_id).first&.name

          csv << [
            hash_uuid(bp.id),
            hash_uuid(bp.patient_id),
            bp.created_at,
            bp.recorded_at,
            original_else_blank_value(facility_name),
            hashed_else_blank_value(user_id),
            bp.systolic,
            bp.diastolic
          ]
        end
      end
    end

    def self.medicines_csv(medicines)
      CSV.generate(headers: true) do |csv|
        csv << AnonymizedDataConstants.medicines_headers.map(&:titleize)

        medicines.each do |med|
          user_id = AuditLog.where(auditable_id: med.id).first
          facility_name = Facility.where(id: med.facility_id).first&.name

          csv << [
            hash_uuid(med.id),
            hash_uuid(med.patient_id),
            original_else_blank_value(facility_name),
            hashed_else_blank_value(user_id),
            med.name,
            med.dosage
          ]
        end
      end
    end

    def self.appointments_csv(appointments)
      CSV.generate(headers: true) do |csv|
        csv << AnonymizedDataConstants.appointment_headers.map(&:titleize)

        appointments.each do |app|
          user_id = AuditLog.where(auditable_id: app.id).first
          facility_name = Facility.where(id: app.facility_id).first&.name

          csv << [
            hash_uuid(app.id),
            hash_uuid(app.patient_id),
            app.created_at,
            original_else_blank_value(facility_name),
            hashed_else_blank_value(user_id),
            app.scheduled_date
          ]
        end
      end
    end

    def self.overdue_csv(overdue_appointments)
      CSV.generate(headers: true) do |csv|
        csv << AnonymizedDataConstants::overdue_headers.map(&:titleize)

        overdue_appointments.each do |overdue_appointment|
          user_id = AuditLog.where(auditable_id: overdue_appointment.id).first
          facility_name = Facility.where(id: overdue_appointment.facility_id).first&.name
          agreed_to_visit = overdue_appointment.agreed_to_visit
          remind_on = overdue_appointment.remind_on
          cancel_reason = overdue_appointment.cancel_reason

          csv << [
            hash_uuid(overdue_appointment.id),
            hash_uuid(overdue_appointment.patient_id),
            overdue_appointment.created_at,
            original_else_blank_value(facility_name),
            hashed_else_blank_value(user_id),
            overdue_appointment.status,
            original_else_blank_value(agreed_to_visit),
            original_else_blank_value(remind_on),
            original_else_blank_value(cancel_reason)
          ]
        end
      end
    end

    def self.communications_csv(communications)
      CSV.generate(headers: true) do |csv|
        csv << AnonymizedDataConstants::communications_headers.map(&:titleize)

        communications.each do |communication|
          patient_id = Patient.where(id: Appointment.where(id: communication.appointment_id).first).first
          communication_result = communication.detailable_type.constantize.where(id: communication.detailable_id).first&.result

          csv << [
            hash_uuid(communication.id),
            hash_uuid(communication.appointment_id),
            hashed_else_blank_value(patient_id),
            hashed_else_blank_value(communication.user_id),
            communication.created_at,
            original_else_blank_value(communication.communication_type),
            original_else_blank_value(communication_result)
          ]
        end
      end
    end

    private

    def self.original_else_blank_value(value)
      if value.blank?
        UNAVAILABLE
      else
        value
      end
    end

    def self.hashed_else_blank_value(value)
      if value.blank?
        UNAVAILABLE
      else
        hash_uuid(value)
      end
    end
  end

  module AnonymizedDataConstants
    PATIENTS_FILE = 'patients.csv'
    BPS_FILE = 'blood_pressures.csv'
    MEDICINES_FILE = 'medicines.csv'
    APPOINTMENTS_FILE = 'appointments.csv'
    OVERDUES_FILE = 'overdue_appointments.csv'
    COMMUNICATIONS_FILE = 'communications.csv'

    def self.patient_headers
      %w[id created_at registration_date facility_name user_id age gender]
    end

    def self.bp_headers
      %w[id patient_id created_at bp_date facility_name user_id bp_systolic bp_diastolic]
    end

    def self.medicines_headers
      %w[id patient_id created_at facility_name user_id medicine_name dosage]
    end

    def self.appointment_headers
      %w[id patient_id created_at facility_name user_id appointment_date]
    end

    def self.overdue_headers
      %w[id patient_id created_at facility_name user_id status agreed_to_visit remind_on cancel_reason]
    end

    def self.communications_headers
      %w[id appointment_id patient_id user_id created_at communication_type communication_result]
    end
  end
end
