require "rails_helper"

RSpec.describe VisitedButNoBPService do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :supervisor, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  let(:june_1_2018) { Time.parse("June 1, 2018 00:00:00+00:00") }
  let(:june_1_2020) { Time.parse("June 1, 2020 00:00:00+00:00") }
  let(:june_30_2020) { Time.parse("June 30, 2020 00:00:00+00:00") }
  let(:may_1_2019) { Time.parse("May 1 2019 00:00:00:00+00:00") }
  let(:may_15_2020) { Time.parse("May 15 2020") }
  let(:july_1_2019) { Time.parse("July 1, 2019 00:00:00+00:00") }
  let(:july_2020) { Time.parse("July 15, 2020 00:00:00+00:00") }
  let(:jan_2019) { Time.parse("January 1st, 2019 00:00:00+00:00") }
  let(:jan_2020) { Time.parse("January 1st, 2020 00:00:00+00:00") }
  let(:july_2018) { Time.parse("July 1st, 2018 00:00:00+00:00") }
  let(:july_2020) { Time.parse("July 1st, 2020 00:00:00+00:00") }

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatientPerQuarter.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  it "counts missed visits as patients who have visitede between 3 to 12 months ago" do
    may_1 = Time.parse("May 1st, 2020")
    facility = create(:facility, facility_group: facility_group_1)
    facility_2 = create(:facility)
    patient_visited_via_appt = create(:patient, registration_facility: facility)
    patient_visited_via_drugs = create(:patient, full_name: "visit via drugs", registration_facility: facility)
    patient_visited_via_drugs.prescription_drugs << build(:prescription_drug, device_created_at: may_15_2020)
    patient_visited_via_blood_sugar = create(:patient, full_name: "visit via blood sugar", registration_facility: facility)
    patient_visited_via_blood_sugar.blood_sugars << build(:blood_sugar, device_created_at: may_15_2020)
    patient_visited_one_year_ago = create(:patient, full_name: "visited one year ago", registration_facility: facility, recorded_at: Time.parse("June 1st 2019"))
    patient_visited_one_year_ago.prescription_drugs << build(:prescription_drug, device_created_at: july_1_2019)

    patient_without_visit_and_bp = create(:patient, full_name: "no visits and no BP", registration_facility: facility)

    patient_with_bp = create(:patient, registration_facility: facility)
    _appointment_1 = create(:appointment, creation_facility: facility, scheduled_date: may_1, device_created_at: may_1, patient: patient_visited_via_appt)
    _appointment_2 = create(:appointment, creation_facility: facility, scheduled_date: may_15_2020, device_created_at: may_15_2020, patient: patient_with_bp)
    _appointment_3 = create(:appointment, creation_facility: facility, scheduled_date: may_15_2020, device_created_at: may_15_2020, patient: patient_visited_via_appt)
    create(:blood_pressure, :under_control, facility: facility, patient: patient_with_bp, recorded_at: may_15_2020)
    patient_from_different_facility = FactoryBot.create(:patient, registration_facility: facility_2)
    _appointment_4 = create(:appointment, creation_facility: facility_2, scheduled_date: may_15_2020, device_created_at: may_15_2020, patient: patient_from_different_facility)

    periods = (july_2018.to_period..july_2020.to_period)
    service = VisitedButNoBPService.new(facility, periods: periods)
    (Period.month(may_1)..Period.month(july_2020)).each do |period|
      result = service.patients_visited_with_no_bp_taken(period)
      expect(result).to_not include(patient_with_bp, patient_without_visit_and_bp)
      expect(result).to include(patient_visited_via_appt, patient_visited_via_drugs, patient_visited_via_blood_sugar)
    end
    results = service.call
    old_visit_results = results.fetch_values(july_1_2019.to_period, Period.month("August 1st 2019"),
      Period.month("September 1st 2019"), Period.month("October 1st 2019"))
    expect(old_visit_results).to eq([1, 1, 1, 0])

    actual = results.fetch_values(may_1.to_period, june_1_2020.to_period, july_2020.to_period)
    expect(actual).to eq([3, 3, 3])
  end
end
