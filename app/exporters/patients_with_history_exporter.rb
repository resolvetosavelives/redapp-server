class PatientsWithHistoryExporter < PatientsExporter
  DISPLAY_BLOOD_PRESSURES = 3
  DISPLAY_MEDICATION_COLUMNS = 5

  def csv_headers
    [
      "Registration Date",
      "Registration Quarter",
      "Patient died?",
      "Simple Patient ID",
      "BP Passport ID",
      "Patient Name",
      "Patient Age",
      "Patient Gender",
      "Patient Phone Number",
      "Patient Street Address",
      "Patient Village/Colony",
      "Patient District",
      (zone_column if Rails.application.config.country[:patient_line_list_show_zone]),
      "Patient State",
      "Preferred Facility Name",
      "Preferred Facility Type",
      "Preferred Facility District",
      "Preferred Facility State",
      "Registration Facility Name",
      "Registration Facility Type",
      "Registration Facility District",
      "Registration Facility State",
      "Diagnosed with Hypertension",
      "Diagnosed with Diabetes",
      "Risk Level",
      "Days Overdue For Next Follow-up",
      (1..DISPLAY_BLOOD_PRESSURES).map do |i|
        [
          "BP #{i} Date",
          "BP #{i} Quarter",
          "BP #{i} Systolic",
          "BP #{i} Diastolic",
          "BP #{i} Facility Name",
          "BP #{i} Facility Type",
          "BP #{i} Facility District",
          "BP #{i} Facility State",
          "BP #{i} Follow-up Facility",
          "BP #{i} Follow-up Date",
          "BP #{i} Follow up Days",
          "BP #{i} Medication Titrated",
          "BP #{i} Medication 1",
          "BP #{i} Dosage 1",
          "BP #{i} Medication 2",
          "BP #{i} Dosage 2",
          "BP #{i} Medication 3",
          "BP #{i} Dosage 3",
          "BP #{i} Medication 4",
          "BP #{i} Dosage 4",
          "BP #{i} Medication 5",
          "BP #{i} Dosage 5",
          "BP #{i} Other Medications"
        ]
      end,
      "Latest Blood Sugar Date",
      "Latest Blood Sugar Value",
      "Latest Blood Sugar Type"
    ].flatten.compact
  end

  def csv_fields(patient_summary)
    latest_bps = patient_summary.patient.latest_blood_pressures.first(DISPLAY_BLOOD_PRESSURES + 1)
    fetch_medication_history(patient_summary.patient, latest_bps.map(&:recorded_at))
    zone_column_index = csv_headers.index(zone_column)

    csv_fields = [
      patient_summary.recorded_at.presence &&
        I18n.l(patient_summary.recorded_at.to_date),

      patient_summary.recorded_at.presence &&
        quarter_string(patient_summary.recorded_at.to_date),

      ("Died" if patient_summary.status == "dead"),
      patient_summary.id,
      patient_summary.latest_bp_passport.shortcode,
      patient_summary.full_name,
      patient_summary.current_age.to_i,
      patient_summary.gender.capitalize,
      patient_summary.latest_phone_number,
      patient_summary.street_address,
      patient_summary.village_or_colony,
      patient_summary.district,
      patient_summary.state,
      patient_summary.assigned_facility_name,
      patient_summary.assigned_facility_type,
      patient_summary.assigned_facility_district,
      patient_summary.assigned_facility_state,
      patient_summary.registration_facility_name,
      patient_summary.registration_facility_type,
      patient_summary.registration_district,
      patient_summary.registration_state,
      patient_summary.hypertension,
      patient_summary.diabetes,
      ("High" if patient_summary.patient.high_risk?),
      patient_summary.days_overdue.to_i,
      (1..DISPLAY_BLOOD_PRESSURES).map do |i|
        bp = latest_bps[i - 1]
        previous_bp = latest_bps[i]
        appointment = appointment_created_on(patient_summary.patient, bp&.recorded_at)

        [bp&.recorded_at.presence && I18n.l(bp&.recorded_at&.to_date),
          bp&.recorded_at.presence && quarter_string(bp&.recorded_at&.to_date),
          bp&.systolic,
          bp&.diastolic,
          bp&.facility&.name,
          bp&.facility&.facility_type,
          bp&.facility&.district,
          bp&.facility&.state,
          appointment&.facility&.name,
          appointment&.scheduled_date.presence && I18n.l(appointment&.scheduled_date&.to_date),
          appointment&.follow_up_days,
          medication_updated?(bp&.recorded_at, previous_bp&.recorded_at),
          *formatted_medications(bp&.recorded_at)]
      end,
      patient_summary.latest_blood_pressure_recorded_at.presence &&
        I18n.l(patient_summary.latest_blood_pressure_recorded_at.to_date),

      "#{patient_summary.latest_blood_sugar_value} #{BloodSugar::BLOOD_SUGAR_UNITS[patient_summary.latest_blood_sugar_type]}",

      patient_summary.latest_blood_sugar_type.presence &&
        BLOOD_SUGAR_TYPES[patient_summary.latest_blood_sugar_type],
    ].flatten

    csv_fields.insert(zone_column_index, patient_summary.block) if zone_column_index
    csv_fields
  end

  private

  def appointment_created_on(patient, date)
    patient.appointments
      .where(device_created_at: date&.all_day)
      .order(device_created_at: :asc)
      .first
  end

  def fetch_medication_history(patient, dates)
    @medications = dates.each_with_object({}) { |date, cache|
      cache[date] = date ? patient.prescribed_drugs(date: date) : PrescriptionDrug.none
    }
  end

  def medications(date)
    date ? @medications[date] : PrescriptionDrug.none
  end

  def medication_updated?(date, previous_date)
    current_medications = medications(date)
    previous_medications = medications(previous_date)
    current_medications == previous_medications ? "No" : "Yes"
  end

  def formatted_medications(date)
    medications = medications(date)
    sorted_medications = medications.order(is_protocol_drug: :desc, name: :asc)
    other_medications = sorted_medications[DISPLAY_MEDICATION_COLUMNS..medications.length]
                            &.map { |medication| "#{medication.name}-#{medication.dosage}" }
                            &.join(", ")

    (0...DISPLAY_MEDICATION_COLUMNS).flat_map { |i|
      [sorted_medications[i]&.name, sorted_medications[i]&.dosage]
    } << other_medications
  end
end
