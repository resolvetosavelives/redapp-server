require "rails_helper"

RSpec.describe Facility, type: :model do
  describe "Associations" do
    it { should have_many(:users) }
    it { should have_many(:blood_pressures).through(:encounters).source(:blood_pressures) }
    it { should have_many(:blood_sugars).through(:encounters).source(:blood_sugars) }
    it { should have_many(:prescription_drugs) }
    it { should have_many(:patients).through(:encounters) }
    it { should have_many(:appointments) }
    it { should have_many(:teleconsultations) }
    it { should have_and_belong_to_many(:teleconsultation_medical_officers) }

    it { should have_many(:registered_patients).class_name("Patient").with_foreign_key("registration_facility_id") }
    it { should have_many(:assigned_patients).class_name("Patient").with_foreign_key("assigned_facility_id") }
    it { should have_many(:assigned_hypertension_patients).class_name("Patient").with_foreign_key("assigned_facility_id") }

    it "does not change the slug when renamed" do
      facility = create(:facility, name: "old_name")
      original_slug = facility.slug
      facility.name = "new name"
      facility.valid?
      facility.save!
      expect(facility.slug).to eq(original_slug)
    end

    context "patients" do
      it "has distinct patients" do
        facility = create(:facility)
        dm_patient = create(:patient, :diabetes)
        htn_patient = create(:patient)

        create(:blood_sugar, :with_encounter, facility: facility, patient: dm_patient)
        create(:blood_sugar, :with_encounter, facility: facility, patient: htn_patient)
        create(:blood_pressure, :with_encounter, facility: facility, patient: htn_patient)
        create(:blood_pressure, :with_encounter, facility: facility, patient: dm_patient)

        expect(facility.patients.count).to eq(2)
      end
    end

    it { should belong_to(:facility_group).optional }
    it { should delegate_method(:follow_ups_by_period).to(:patients).with_prefix(:patient) }

    describe ".assigned_hypertension_patients" do
      let!(:assigned_facility) { create(:facility) }
      let!(:registration_facility) { create(:facility) }
      let!(:assigned_patients) do
        [create(:patient,
          assigned_facility: assigned_facility,
          registration_facility: registration_facility),
          create(:patient,
            :without_hypertension,
            assigned_facility: assigned_facility,
            registration_facility: registration_facility)]
      end

      it "returns assigned hypertensive patients for facilities" do
        expect(assigned_facility.assigned_hypertension_patients).to contain_exactly assigned_patients.first
      end

      it "ignores registration patients" do
        expect(registration_facility.assigned_hypertension_patients).to be_empty
      end
    end

    describe "#teleconsultation_medical_officers" do
      let!(:facility) { create(:facility) }
      let!(:medical_officer) { create(:user, teleconsultation_facilities: [facility]) }

      specify do
        expect(facility.teleconsultation_medical_officers).to contain_exactly medical_officer
      end
    end
  end

  describe "Delegates" do
    context "#patient_follow_ups_by_period" do
      it "counts follow_ups across HTN and DM" do
        registration_date = Time.new(2018, 4, 8)
        first_follow_up_date = registration_date + 1.month
        second_follow_up_date = first_follow_up_date + 1.month

        facility = create(:facility)
        dm_patient = create(:patient, :diabetes, recorded_at: registration_date)
        htn_patient = create(:patient, recorded_at: registration_date)

        create(:blood_sugar, :with_encounter, facility: facility, patient: dm_patient, recorded_at: first_follow_up_date)
        create(:blood_sugar, :with_encounter, facility: facility, patient: htn_patient, recorded_at: first_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: htn_patient, recorded_at: second_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: dm_patient, recorded_at: second_follow_up_date)

        expected_output = {
          first_follow_up_date.to_date.beginning_of_month => 2,
          second_follow_up_date.to_date.beginning_of_month => 2
        }

        expect(facility.patient_follow_ups_by_period(:month).count).to eq(expected_output)
      end
    end

    context "#hypertension_follow_ups_by_period" do
      it "counts follow_ups only for hypertensive patients" do
        registration_date = Time.new(2018, 4, 8)
        first_follow_up_date = registration_date + 1.month
        second_follow_up_date = first_follow_up_date + 1.month

        facility = create(:facility)
        dm_patient = create(:patient, :diabetes, recorded_at: registration_date)
        htn_patient = create(:patient, recorded_at: registration_date)

        create(:blood_sugar, :with_encounter, facility: facility, patient: dm_patient, recorded_at: first_follow_up_date)
        create(:blood_sugar, :with_encounter, facility: facility, patient: htn_patient, recorded_at: first_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: htn_patient, recorded_at: second_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: dm_patient, recorded_at: second_follow_up_date)

        expected_output = {
          second_follow_up_date.to_date.beginning_of_month => 1
        }

        expect(facility.hypertension_follow_ups_by_period(:month).count).to eq(expected_output)
      end

      it "counts the patients' hypertension follow ups at the facility only" do
        facilities = create_list(:facility, 2)
        patient = create(:patient, :hypertension, recorded_at: 10.months.ago)

        create(:blood_pressure, :with_encounter, recorded_at: 3.months.ago, facility: facilities.first, patient: patient)
        create(:blood_pressure, :with_encounter, recorded_at: 1.month.ago, facility: facilities.second, patient: patient)

        expect(facilities.first.hypertension_follow_ups_by_period(:month, last: 4).count[1.month.ago.beginning_of_month.to_date]).to eq 0
        expect(facilities.second.hypertension_follow_ups_by_period(:month, last: 4).count[3.months.ago.beginning_of_month.to_date]).to eq 0

        expect(facilities.first.hypertension_follow_ups_by_period(:month, last: 4).count[3.month.ago.beginning_of_month.to_date]).to eq 1
        expect(facilities.second.hypertension_follow_ups_by_period(:month, last: 4).count[1.months.ago.beginning_of_month.to_date]).to eq 1
      end
    end

    context "#diabetes_follow_ups_by_period" do
      it "counts follow_ups only for diabetic patients" do
        registration_date = Time.new(2018, 4, 8)
        first_follow_up_date = registration_date + 1.month
        second_follow_up_date = first_follow_up_date + 1.month

        facility = create(:facility)
        dm_patient = create(:patient, :diabetes, recorded_at: registration_date)
        htn_patient = create(:patient, recorded_at: registration_date)

        create(:blood_sugar, :with_encounter, facility: facility, patient: dm_patient, recorded_at: first_follow_up_date)
        create(:blood_sugar, :with_encounter, facility: facility, patient: htn_patient, recorded_at: first_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: htn_patient, recorded_at: second_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: dm_patient, recorded_at: second_follow_up_date)

        expected_output = {
          first_follow_up_date.to_date.beginning_of_month => 1
        }

        expect(facility.diabetes_follow_ups_by_period(:month).count).to eq(expected_output)
      end

      it "counts the patients' diabetes follow ups at the facility only" do
        facilities = create_list(:facility, 2)
        patient = create(:patient, :diabetes, recorded_at: 10.months.ago)

        create(:blood_sugar, :with_encounter, recorded_at: 3.months.ago, facility: facilities.first, patient: patient)
        create(:blood_sugar, :with_encounter, recorded_at: 1.month.ago, facility: facilities.second, patient: patient)

        expect(facilities.first.diabetes_follow_ups_by_period(:month, last: 4).count[1.month.ago.beginning_of_month.to_date]).to eq 0
        expect(facilities.second.diabetes_follow_ups_by_period(:month, last: 4).count[3.months.ago.beginning_of_month.to_date]).to eq 0

        expect(facilities.first.diabetes_follow_ups_by_period(:month, last: 4).count[3.month.ago.beginning_of_month.to_date]).to eq 1
        expect(facilities.second.diabetes_follow_ups_by_period(:month, last: 4).count[1.months.ago.beginning_of_month.to_date]).to eq 1
      end
    end
  end

  describe "Validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:district) }
    it { should validate_presence_of(:state) }
    it { should validate_presence_of(:country) }
    it { should validate_numericality_of(:pin) }
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  describe "#cohort_analytics" do
    it "considers only registered hypertensive patients" do
      facility = create(:facility)

      Timecop.freeze("June 15th 2019") do
        _non_htn_patients = create_list(:patient, 2, :without_hypertension, assigned_facility: facility, recorded_at: 3.months.ago)
        _htn_patients = create_list(:patient, 2, assigned_facility: facility, recorded_at: 3.months.ago)

        result = facility.cohort_analytics(period: :month, prev_periods: 3)
        april_key = [Date.parse("March 1st 2019"), Date.parse("April 1st 2019")]
        april_data = result[april_key]
        expect(april_data["cohort_patients"]).to eq({facility.id => 2, "total" => 2})
      end
    end
  end

  describe "Search" do
    let!(:facility_1) { create(:facility, name: "HWC Bahadurgarh") }
    let!(:facility_2) { create(:facility, name: "CHC Docomo", slug: "chc-docomo") }
    let!(:facility_3) { create(:facility, name: "CHC Porla Docomo") }

    ["CHC", "DoCoMo", "DOCOMO", "docomo", "cHc", "chc"].each do |term|
      it "matches on case-insensitive searches: #{term.inspect}" do
        expect(Facility.search_by_name(term)).to match_array([facility_2, facility_3])
      end
    end

    ["Bahadurgarh", "hwc", "HWC Bahadurgarh"].each do |term|
      it "matches on facility name: #{term.inspect}" do
        expect(Facility.search_by_name(term)).to match_array(facility_1)
      end
    end

    it "matches on facility slugs" do
      expect(Facility.search_by_name("chc-docomo")).to match_array(facility_2)
    end

    ["ch", "doco"].each do |term|
      it "partially matches on facility names: #{term.inspect}" do
        expect(Facility.search_by_name(term)).to match_array([facility_2, facility_3])
      end
    end

    ["\n\n", ""].each do |term|
      it "returns nothing for unmatched searches: #{term.inspect}" do
        expect(Facility.search_by_name(term)).to be_empty
      end
    end

    ["chc\n\n\r", "\b      chc         "].each do |term|
      it "ignores escape characters and whitespace around words: #{term.inspect}" do
        expect(Facility.search_by_name(term)).to match_array([facility_2, facility_3])
      end
    end
  end

  describe ".parse_facilities" do
    let(:upload_file) { fixture_file_upload("files/upload_facilities_test.csv", "text/csv") }

    it "parses the facilities" do
      facilities = described_class.parse_facilities(upload_file)
      expect(facilities.first).to include(organization_name: "OrgOne",
                                          facility_group_name: "FGTwo",
                                          name: "Test Facility",
                                          facility_type: "CHC",
                                          district: "Bhatinda",
                                          state: "Punjab",
                                          country: "India",
                                          enable_diabetes_management: "true",
                                          import: true)
      expect(facilities.second).to include(organization_name: "OrgOne",
                                           facility_group_name: "FGTwo",
                                           name: "Test Facility 2",
                                           facility_type: "CHC",
                                           district: "Bhatinda",
                                           state: "Punjab",
                                           country: "India",
                                           import: true)
    end

    it "defaults enable_diabetes_management to false if blank" do
      facilities = described_class.parse_facilities(upload_file)
      expect(facilities.second[:enable_diabetes_management]).to be false
    end
  end

  describe "OPD load estimatation" do
    let(:facility) { create(:facility) }

    it "indicates if a user value for OPD is present" do
      facility.monthly_estimated_opd_load = 999
      expect(facility.opd_load_estimated?).to be true

      facility.monthly_estimated_opd_load = nil
      expect(facility.opd_load_estimated?).to be false
    end

    it "uses OPD loads from the user when present" do
      facility.monthly_estimated_opd_load = 999
      expect(facility.opd_load).to eq(999)
    end

    it "estimates OPD loads based on facility size when user value not present" do
      facility.monthly_estimated_opd_load = nil

      facility.facility_size = "community"
      expect(facility.opd_load).to eq(450)

      facility.facility_size = "small"
      expect(facility.opd_load).to eq(1800)

      facility.facility_size = "medium"
      expect(facility.opd_load).to eq(3000)

      facility.facility_size = "large"
      expect(facility.opd_load).to eq(7500)
    end
  end

  describe "Attribute sanitization" do
    it "squishes and upcases the first letter of the name" do
      facility = FactoryBot.create(:facility, name: " cH name  1  ")
      expect(facility.name).to eq("CH name 1")
    end

    it "squishes and upcases the first letter of the district name" do
      facility = FactoryBot.create(:facility, district: " district name   chennai  ")
      expect(facility.district).to eq("District name chennai")
    end
  end

  describe "#teleconsultation_phone_number_with_isd" do
    it "returns the first teleconsultation phone number with isd code" do
      facility = create(:facility, enable_teleconsultation: true)
      medical_officer_1 = create(:user, teleconsultation_phone_number: "1111111111", teleconsultation_isd_code: "+91")
      medical_officer_2 = create(:user, teleconsultation_phone_number: "2222222222", teleconsultation_isd_code: "+91")

      facility.teleconsultation_medical_officers = [medical_officer_1, medical_officer_2]
      facility.save!

      expect(facility.teleconsultation_phone_number_with_isd).to be_in(["+911111111111", "+912222222222"])
    end
  end

  describe "#teleconsultation_phone_numbers_with_isd" do
    it "returns all the teleconsultation phone numbers with isd code" do
      facility = create(:facility, enable_teleconsultation: true)
      medical_officer_1 = create(:user, teleconsultation_phone_number: "1111111111", teleconsultation_isd_code: "+91")
      medical_officer_2 = create(:user, teleconsultation_phone_number: "2222222222", teleconsultation_isd_code: "+91")

      facility.teleconsultation_medical_officers = [medical_officer_1, medical_officer_2]
      facility.save!

      expect(facility.teleconsultation_phone_numbers_with_isd).to match_array(["+911111111111", "+912222222222"])
    end
  end

  describe ".discardable?" do
    let!(:facility) { create(:facility) }

    context "isn't discardable if data exists" do
      it "has patients" do
        create(:patient, registration_facility: facility)
        expect(facility.discardable?).to be false
      end

      it "has blood pressures" do
        blood_pressure = create(:blood_pressure, facility: facility)
        create(:encounter, :with_observables, observable: blood_pressure)
        expect(facility.discardable?).to be false
      end

      it "has blood sugars" do
        blood_sugar = create(:blood_sugar, facility: facility)
        create(:encounter, :with_observables, observable: blood_sugar)
        expect(facility.discardable?).to be false
      end

      it "has appointments" do
        create(:appointment, facility: facility)
        expect(facility.discardable?).to be false
      end
    end

    context "is discardable if no data exists" do
      it "has no data" do
        expect(facility.discardable?).to be true
      end
    end
  end
end
