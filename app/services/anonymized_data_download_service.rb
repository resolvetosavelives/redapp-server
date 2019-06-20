require 'csv'

class AnonymizedDataDownloadService
  PATIENTS_FILE = 'patients.csv'
  BPS_FILE = 'blood_pressures.csv'
  MEDICINES_FILE = 'medicines.csv'
  APPOINTMENTS_FILE = 'appointments.csv'
  SMS_REMINDERS_FILE = 'sms_reminders.csv'
  PHONE_CALLS_FILE = 'phone_calls.csv'

  def run_for_district(recipient_name, recipient_email, district_name, organization_id)
    organization_district = OrganizationDistrict.new(district_name, Organization.find(organization_id))
    organization_district_patients = organization_district.facilities.flat_map(&:patients)
    anonymized_data = anonymize(organization_district_patients)

    AnonymizedDataDownloadMailer
      .with(recipient_name: recipient_name,
            recipient_email: recipient_email,
            anonymized_data: anonymized_data)
      .mail_anonymized_data
      .deliver_later
  end

  def run_for_facility(recipient_name, recipient_email, facility_id)
    facility = Facility.find(facility_id)
    facility_patients = facility.patients
    anonymized_data = anonymize(facility_patients)

    AnonymizedDataDownloadMailer
      .with(recipient_name: recipient_name,
            recipient_email: recipient_email,
            anonymized_data: anonymized_data)
      .mail_anonymized_data
      .deliver_later
  end

  private

  def anonymize(patients)
    patient_ids = patients.map(&:id).to_set

    csv_data = Hash.new

    csv_data[PATIENTS_FILE] = to_csv(patients)

    blood_pressures = BloodPressure.all.select { |bp| patient_ids.include?(bp.patient_id) }
    blood_pressures_csv_data = to_csv(blood_pressures)
    csv_data[BPS_FILE] = blood_pressures_csv_data if blood_pressures_csv_data.present?

    prescriptions = PrescriptionDrug.all.select { |pd| patient_ids.include?(pd.patient_id) }
    prescriptions_csv_data = to_csv(prescriptions)
    csv_data[MEDICINES_FILE] = prescriptions_csv_data if prescriptions_csv_data.present?

    appointments = Appointment.all.select { |app| patient_ids.include?(app.patient_id) }
    appointments_csv_data = to_csv(appointments)
    csv_data[APPOINTMENTS_FILE] = appointments_csv_data if appointments_csv_data.present?

    communications = appointments.flat_map(&:communications)
    communications_csv_data = to_csv(communications)
    csv_data[SMS_REMINDERS_FILE] = communications_csv_data if communications_csv_data.present?

    all_bp_users_phone_numbers = blood_pressures.flat_map(&:user).compact.map(&:phone_number).uniq
    phone_calls = CallLog.all.select { |call| all_bp_users_phone_numbers.include?(call.caller_phone_number) }
    phone_calls_csv_data = to_csv(phone_calls)
    csv_data[PHONE_CALLS_FILE] = phone_calls_csv_data if phone_calls_csv_data.present?

    csv_data
  end

  def to_csv(resources)
    return unless resources.present?

    klass = resources.first.class
    headers = klass::ANONYMIZED_DATA_FIELDS

    CSV.generate(headers: true) do |csv|
      csv << headers.map(&:titleize)

      resources.map do |r|
        values = r.anonymized_data
        csv << headers.map do |h|
          values[h.to_sym]
        end
      end
    end
  end
end