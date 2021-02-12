require "rails_helper"

describe Patient, type: :model do
  def refresh_views
    LatestBloodPressuresPerPatientPerMonth.refresh
  end

  subject(:patient) { build(:patient) }

  it "picks up available genders from country config" do
    expect(described_class::GENDERS).to eq(Rails.application.config.country[:supported_genders])
  end

  describe "factory fixtures" do
    it "can create a valid patient" do
      expect {
        patient = create(:patient)
        expect(patient).to be_valid
      }.to change { Patient.count }.by(1)
        .and change { PatientBusinessIdentifier.count }.by(1)
        .and change { MedicalHistory.count }.by(1)
    end
  end

  describe "Associations" do
    it { is_expected.to have_one(:medical_history) }

    it { is_expected.to have_many(:phone_numbers) }
    it { is_expected.to have_many(:business_identifiers) }
    it { is_expected.to have_many(:passport_authentications).through(:business_identifiers) }

    it { is_expected.to have_many(:blood_pressures) }
    it { is_expected.to have_many(:blood_sugars) }
    it { is_expected.to have_many(:prescription_drugs) }
    it { is_expected.to have_many(:facilities).through(:blood_pressures) }
    it { is_expected.to have_many(:users).through(:blood_pressures) }
    it { is_expected.to have_many(:appointments) }
    it { is_expected.to have_many(:teleconsultations) }

    it { is_expected.to have_many(:encounters) }
    it { is_expected.to have_many(:observations).through(:encounters) }

    it { is_expected.to belong_to(:address).optional }
    it { is_expected.to belong_to(:registration_facility).class_name("Facility").optional }
    it { is_expected.to belong_to(:registration_user).class_name("User") }

    it "has distinct facilities" do
      patient = create(:patient)
      facility = create(:facility)
      create_list(:blood_pressure, 5, :with_encounter, patient: patient, facility: facility)

      expect(patient.facilities.count).to eq(1)
    end

    it { is_expected.to belong_to(:registration_facility).class_name("Facility").optional }
    it { is_expected.to belong_to(:registration_user).class_name("User") }

    it { is_expected.to have_many(:latest_blood_pressures).order(recorded_at: :desc).class_name("BloodPressure") }
    it { is_expected.to have_many(:latest_blood_sugars).order(recorded_at: :desc).class_name("BloodSugar") }

    specify do
      is_expected.to have_many(:current_prescription_drugs)
        .conditions(is_deleted: false)
        .class_name("PrescriptionDrug")
    end

    specify do
      is_expected.to have_many(:latest_scheduled_appointments)
        .conditions(status: "scheduled")
        .order(scheduled_date: :desc)
        .class_name("Appointment")
    end

    specify do
      is_expected.to have_many(:latest_bp_passports)
        .conditions(identifier_type: "simple_bp_passport")
        .order(device_created_at: :desc)
        .class_name("PatientBusinessIdentifier")
    end
  end

  describe "Validations" do
    it_behaves_like "a record that validates device timestamps"

    it "validates that date of birth is not in the future" do
      patient = build(:patient)
      patient.date_of_birth = 3.days.from_now
      expect(patient).to be_invalid
    end

    it "validates status" do
      patient = Patient.new

      # valid statuses should not cause problems
      patient.status = "active"
      patient.status = "dead"
      patient.status = "migrated"
      patient.status = "unresponsive"
      patient.status = "inactive"

      # invalid statuses should raise errors
      expect { patient.status = "something else" }.to raise_error(ArgumentError)
    end
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  context "Scopes" do
    describe ".with_diabetes" do
      it "only includes patients with diagnosis of diabetes" do
        dm_patients = create_list(:patient, 2, :diabetes)
        _htn_patients = create(:patient)

        expect(Patient.with_diabetes).to match_array(dm_patients)
      end
    end

    describe ".with_hypertension" do
      it "only includes patients with diagnosis of hypertension" do
        htn_patients = [
          create(:patient),
          create(:patient).tap { |patient| create(:medical_history, :hypertension_yes, patient: patient) }
        ]

        _non_htn_patients = [
          create(:patient, :without_hypertension),
          create(:patient).tap { |patient| patient.medical_history.discard },
          create(:patient).tap { |patient| patient.medical_history.destroy }
        ]

        expect(Patient.with_hypertension).to match_array(htn_patients)
      end
    end

    context "follow ups" do
      let(:reg_date) { Date.new(2018, 1, 1) }
      let(:current_user) { create(:user) }
      let(:current_facility) { create(:facility, facility_group: current_user.facility.facility_group) }
      let(:follow_up_facility) { create(:facility, facility_group: current_user.facility.facility_group) }
      let(:hypertensive_patient) { create(:patient, registration_facility: current_facility, recorded_at: reg_date) }
      let(:diabetic_patient) {
        create(:patient,
          :diabetes,
          registration_facility: current_facility,
          recorded_at: reg_date)
      }
      let(:first_follow_up_date) { reg_date + 1.month }
      let(:second_follow_up_date) { first_follow_up_date + 1.day }

      before do
        2.times do
          create(:blood_sugar,
            :with_encounter,
            facility: current_facility,
            patient: diabetic_patient,
            user: current_user,
            recorded_at: first_follow_up_date)
          create(:blood_pressure,
            :with_encounter,
            patient: hypertensive_patient,
            facility: current_facility,
            user: current_user,
            recorded_at: first_follow_up_date)
        end

        # visit at a facility different from registration
        create(:blood_pressure,
          :with_encounter,
          patient: hypertensive_patient,
          facility: follow_up_facility,
          user: current_user,
          recorded_at: first_follow_up_date)

        # diabetic patient following up with a BP
        create(:blood_pressure,
          :with_encounter,
          patient: diabetic_patient,
          facility: current_facility,
          user: current_user,
          recorded_at: first_follow_up_date)

        # another follow up in the same month but another day
        create(:blood_pressure,
          :with_encounter,
          patient: hypertensive_patient,
          facility: current_facility,
          user: current_user,
          recorded_at: second_follow_up_date)
      end

      describe ".follow_ups" do
        context "by day" do
          it "groups follow ups by day" do
            expect(Patient
                     .follow_ups_by_period(:day)
                     .count).to eq({first_follow_up_date => 2,
                                    second_follow_up_date => 1})
          end

          it "can be grouped by facility and day" do
            expect(Patient
                     .follow_ups_by_period(:day)
                     .group("encounters.facility_id")
                     .count).to eq({[first_follow_up_date, current_facility.id] => 2,
                                    [first_follow_up_date, follow_up_facility.id] => 1,
                                    [second_follow_up_date, current_facility.id] => 1,
                                    [second_follow_up_date, follow_up_facility.id] => 0})
          end

          it "can be filtered by region" do
            expect(Patient
                     .follow_ups_by_period(:day, at_region: current_facility)
                     .group("encounters.facility_id")
                     .count).to eq({[first_follow_up_date, current_facility.id] => 2,
                                    [second_follow_up_date, current_facility.id] => 1})
          end
        end

        context "by month" do
          it "groups follow ups by month" do
            expect(Patient
                     .follow_ups_by_period(:month)
                     .count).to eq({first_follow_up_date => 2})
          end

          it "can be grouped by facility and day" do
            expect(Patient
                     .follow_ups_by_period(:month)
                     .group("encounters.facility_id")
                     .count).to eq({[first_follow_up_date, current_facility.id] => 2,
                                    [first_follow_up_date, follow_up_facility.id] => 1})
          end

          it "can be filtered by facility" do
            expect(Patient
                     .follow_ups_by_period(:month, at_region: current_facility)
                     .group("encounters.facility_id")
                     .count).to eq({[first_follow_up_date, current_facility.id] => 2})
          end
        end
      end

      describe ".diabetes_follow_ups" do
        context "by day" do
          it "groups follow ups by day" do
            expect(Patient
                     .diabetes_follow_ups_by_period(:day)
                     .count).to eq({first_follow_up_date => 1})
          end

          it "can be grouped by facility and day" do
            expect(Patient
                     .diabetes_follow_ups_by_period(:day)
                     .group("blood_sugars.facility_id")
                     .count).to eq({[first_follow_up_date, current_facility.id] => 1})
          end
        end

        context "by month" do
          it "groups follow ups by month" do
            expect(Patient
                     .diabetes_follow_ups_by_period(:month)
                     .count).to eq({first_follow_up_date => 1})
          end

          it "can be grouped by facility and month" do
            expect(Patient
                     .diabetes_follow_ups_by_period(:month)
                     .group("blood_sugars.facility_id")
                     .count).to eq({[first_follow_up_date, current_facility.id] => 1})
          end
        end
      end

      describe ".hypertension_follow_ups" do
        context "by day" do
          it "groups follow ups by day" do
            expect(Patient
                     .hypertension_follow_ups_by_period(:day)
                     .count).to eq({first_follow_up_date => 1,
                                    second_follow_up_date => 1})
          end

          it "can be grouped by facility and day" do
            expect(Patient
                     .hypertension_follow_ups_by_period(:day)
                     .group("blood_pressures.facility_id")
                     .count).to eq({[first_follow_up_date, current_facility.id] => 1,
                                    [first_follow_up_date, follow_up_facility.id] => 1,
                                    [second_follow_up_date, current_facility.id] => 1,
                                    [second_follow_up_date, follow_up_facility.id] => 0})
          end

          it "can be filtered by region" do
            expect(Patient
                     .hypertension_follow_ups_by_period(:day, at_region: current_facility)
                     .group("blood_pressures.facility_id")
                     .count).to eq({[first_follow_up_date, current_facility.id] => 1,
                                    [second_follow_up_date, current_facility.id] => 1})
          end
        end

        context "by month" do
          it "groups follow ups by month" do
            expect(Patient
                     .hypertension_follow_ups_by_period(:month)
                     .count).to eq({first_follow_up_date => 1})
          end

          it "can be grouped by facility and month" do
            expect(Patient
                     .hypertension_follow_ups_by_period(:month)
                     .group("blood_pressures.facility_id")
                     .count).to eq({[first_follow_up_date, current_facility.id] => 1,
                                    [first_follow_up_date, follow_up_facility.id] => 1})
          end

          it "can be filtered by region" do
            expect(Patient
                     .hypertension_follow_ups_by_period(:month, at_region: current_facility)
                     .group("blood_pressures.facility_id")
                     .count).to eq({[first_follow_up_date, current_facility.id] => 1})
          end
        end
      end
    end

    describe ".not_contacted" do
      let(:patient_to_followup) { create(:patient, device_created_at: 5.days.ago) }
      let(:patient_to_not_followup) { create(:patient, device_created_at: 1.day.ago) }
      let(:patient_contacted) { create(:patient, contacted_by_counsellor: true) }
      let(:patient_could_not_be_contacted) { create(:patient, could_not_contact_reason: "dead") }

      it "includes uncontacted patients registered 2 days ago or earlier" do
        expect(Patient.not_contacted).to include(patient_to_followup)
      end

      it "excludes uncontacted patients registered less than 2 days ago" do
        expect(Patient.not_contacted).not_to include(patient_to_not_followup)
      end

      it "excludes already contacted patients" do
        expect(Patient.not_contacted).not_to include(patient_contacted)
      end

      it "excludes patients who could not be contacted" do
        expect(Patient.not_contacted).not_to include(patient_could_not_be_contacted)
      end
    end

    describe ".for_sync" do
      it "includes discarded patients" do
        discarded_patient = create(:patient, deleted_at: Time.now)

        expect(described_class.for_sync).to include(discarded_patient)
      end

      it "includes nested sync resources" do
        _discarded_patient = create(:patient, deleted_at: Time.now)

        expect(described_class.for_sync.first.association(:address).loaded?).to eq true
        expect(described_class.for_sync.first.association(:phone_numbers).loaded?).to eq true
        expect(described_class.for_sync.first.association(:business_identifiers).loaded?).to eq true
      end
    end

    describe ".ltfu_as_of" do
      it "includes patient who is LTFU" do
        ltfu_patient = Timecop.freeze(2.years.ago) { create(:patient) }
        refresh_views

        expect(described_class.ltfu_as_of(Time.current)).to include(ltfu_patient)
      end

      it "excludes patient who is not LTFU because they were registered recently" do
        not_ltfu_patient = Timecop.freeze(6.months.ago) { create(:patient) }
        refresh_views

        expect(described_class.ltfu_as_of(Time.current)).not_to include(not_ltfu_patient)
      end

      it "excludes patient who is not LTFU because they had a BP recently" do
        not_ltfu_patient = Timecop.freeze(2.years.ago) { create(:patient) }
        Timecop.freeze(6.months.ago) { create(:blood_pressure, patient: not_ltfu_patient) }
        refresh_views

        expect(described_class.ltfu_as_of(Time.current)).not_to include(not_ltfu_patient)
      end
    end

    describe ".not_ltfu_as_of" do
      it "excludes patient who is LTFU" do
        ltfu_patient = Timecop.freeze(2.years.ago) { create(:patient) }
        refresh_views

        expect(described_class.not_ltfu_as_of(Time.current)).not_to include(ltfu_patient)
      end

      it "includes patient who is not LTFU because they were registered recently" do
        not_ltfu_patient = Timecop.freeze(6.months.ago) { create(:patient) }
        refresh_views

        expect(described_class.not_ltfu_as_of(Time.current)).to include(not_ltfu_patient)
      end

      it "includes patient who is not LTFU because they had a BP recently" do
        not_ltfu_patient = Timecop.freeze(2.years.ago) { create(:patient) }
        Timecop.freeze(6.months.ago) { create(:blood_pressure, patient: not_ltfu_patient) }
        refresh_views

        expect(described_class.not_ltfu_as_of(Time.current)).to include(not_ltfu_patient)
      end
    end
  end

  context "Utility methods" do
    let(:patient) { create(:patient) }

    describe "#access_tokens" do
      let(:tokens) { ["token1", "token2"] }
      let(:other_tokens) { ["token3", "token4"] }

      before do
        tokens.each do |token|
          passport = create(:patient_business_identifier, patient: patient)
          create(:passport_authentication, access_token: token, patient_business_identifier: passport)
        end

        other_tokens.each do |token|
          create(:passport_authentication, access_token: token)
        end
      end

      it "returns all access tokens for the patient" do
        expect(patient.access_tokens).to match_array(tokens)
      end
    end

    describe "#risk_priority" do
      it "returns regular priority for patients recently overdue" do
        create(:appointment, scheduled_date: 29.days.ago, status: :scheduled, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:REGULAR])
      end

      it "returns high priority for patients overdue with critical bp" do
        create(:blood_pressure, :critical, patient: patient)
        create(:appointment, scheduled_date: 31.days.ago, status: :scheduled, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:HIGH])
      end

      it "returns high priority for hypertensive bp patients with medical history risks" do
        create(:blood_pressure, :hypertensive, patient: patient)
        create(:medical_history, :prior_risk_history, patient: patient)
        create(:appointment, :overdue, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:HIGH])
      end

      it "returns regular priority for patients overdue with only hypertensive bp" do
        create(:blood_pressure, :hypertensive, patient: patient)
        create(:appointment, :overdue, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:REGULAR])
      end

      it "returns regular priority for patients overdue with only medical risk history" do
        create(:medical_history, :prior_risk_history, patient: patient)
        create(:appointment, :overdue, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:REGULAR])
      end

      it "returns regular priority for patients overdue with hypertension" do
        create(:blood_pressure, :hypertensive, patient: patient)
        create(:appointment, :overdue, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:REGULAR])
      end

      it "returns regular priority for patients overdue with low risk" do
        create(:blood_pressure, :under_control, patient: patient)
        create(:appointment, scheduled_date: 2.years.ago, status: :scheduled, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:REGULAR])
      end

      it "returns high priority for patients overdue with high blood sugar" do
        create(:blood_sugar, patient: patient, blood_sugar_type: :random, blood_sugar_value: 300)
        create(:appointment, scheduled_date: 31.days.ago, status: :scheduled, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:HIGH])
      end

      it "returns regular priority for patients overdue with normal blood sugar" do
        create(:blood_sugar, patient: patient, blood_sugar_type: :random, blood_sugar_value: 150)
        create(:appointment, :overdue, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:REGULAR])
      end
    end

    describe "#current_age" do
      it "returns age based on date of birth year if present" do
        patient.date_of_birth = Date.parse("1980-01-01")

        expect(patient.current_age).to eq(Date.current.year - 1980)
      end

      it "returns age based on age_updated_at if date of birth is not present" do
        patient = create(:patient, age: 30, age_updated_at: 25.months.ago, date_of_birth: nil)

        expect(patient.current_age).to eq(32)
      end

      it "returns 0 if age is 0" do
        patient.date_of_birth = nil
        patient.age = 0
        patient.age_updated_at = 2.years.ago

        expect(patient.current_age).to eq(0)
      end
    end

    describe "#latest_phone_number" do
      it "returns the last phone number for the patient" do
        patient = create(:patient)
        _number_1 = create(:patient_phone_number, patient: patient)
        _number_2 = create(:patient_phone_number, patient: patient)
        number_3 = create(:patient_phone_number, patient: patient)

        expect(patient.reload.latest_phone_number).to eq(number_3.number)
      end
    end

    describe "#latest_mobile_number" do
      it "returns the last mobile number for the patient" do
        patient = create(:patient)
        number_1 = create(:patient_phone_number, patient: patient)
        _number_2 = create(:patient_phone_number, phone_type: :landline, patient: patient)
        _number_3 = create(:patient_phone_number, phone_type: :invalid, patient: patient)

        expect(patient.reload.latest_mobile_number).to eq(number_1.number)
      end
    end

    describe "#prescribed_drugs" do
      let!(:date) { Date.parse "01-01-2020" }

      it "returns the prescribed drugs for a patient as of a date" do
        dbl = double("patient.prescribed_as_of")
        allow(patient.prescription_drugs).to receive(:prescribed_as_of).and_return dbl

        expect(patient.prescribed_drugs(date: date)).to be dbl
      end

      it "defaults to current date when no date is passed" do
        expect(patient.prescription_drugs).to receive(:prescribed_as_of).with(Date.current)
        patient.prescribed_drugs
      end
    end
  end

  context "Virtual params" do
    describe "#call_result" do
      it "correctly records successful contact" do
        patient.call_result = "contacted"

        expect(patient.contacted_by_counsellor).to eq(true)
      end

      Patient.could_not_contact_reasons.values.each do |reason|
        it "correctly records could not contact reason: '#{reason}'" do
          patient.call_result = reason

          expect(patient.could_not_contact_reason).to eq(reason)
        end
      end

      it "sets patient status if call indicated they died" do
        patient.call_result = "dead"

        expect(patient.status).to eq("dead")
      end
    end
  end

  context "anonymised data for patients" do
    describe "anonymized_data" do
      it "correctly retrieves the anonymised data for the patient" do
        anonymised_data =
          {id: Hashable.hash_uuid(patient.id),
           created_at: patient.created_at,
           registration_date: patient.recorded_at,
           registration_facility_name: patient.registration_facility.name,
           user_id: Hashable.hash_uuid(patient.registration_user.id),
           age: patient.age,
           gender: patient.gender}

        expect(patient.anonymized_data).to eq anonymised_data
      end
    end
  end

  context ".discard_data" do
    before do
      create_list(:prescription_drug, 2, patient: patient)
      create_list(:appointment, 2, patient: patient)
      create_list(:blood_pressure, 2, :with_encounter, patient: patient)
      create_list(:blood_sugar, 2, :with_encounter, patient: patient)
    end

    it "soft deletes the patient's encounters" do
      patient.discard_data
      expect(Encounter.where(patient: patient)).to be_empty
    end

    it "soft deletes the patient's observations" do
      patient.discard_data
      encounter_ids = Encounter.with_discarded.where(patient: patient).map(&:id)
      expect(Observation.where(encounter_id: encounter_ids)).to be_empty
    end

    it "soft deletes the patient's blood pressures" do
      patient.discard_data
      expect(BloodPressure.where(patient: patient)).to be_empty
    end

    it "soft deletes the patient's blood_sugars" do
      patient.discard_data
      expect(BloodSugar.where(patient: patient)).to be_empty
    end

    it "soft deletes the patient's appointments" do
      patient.discard_data
      expect(Appointment.where(patient: patient)).to be_empty
    end

    it "soft deletes the patient's prescription drugs" do
      patient.discard_data
      expect(PrescriptionDrug.where(patient: patient)).to be_empty
    end

    it "soft deletes the patient's business identifiers" do
      patient.discard_data
      expect(PatientBusinessIdentifier.where(patient: patient)).to be_empty
    end

    it "soft deletes the patient's phone numbers" do
      patient.discard_data
      expect(PatientPhoneNumber.where(patient: patient)).to be_empty
    end

    it "soft deletes the patient's medical history" do
      patient.discard_data
      expect(MedicalHistory.where(patient: patient)).to be_empty
    end

    it "soft deletes the patient's address" do
      patient.discard_data
      expect(Address.where(id: patient.address_id)).to be_empty
    end
  end
end
