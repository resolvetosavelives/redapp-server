require 'rails_helper'

RSpec.describe Analytics::PatientSetAnalytics do
  let(:one_year_ago) { Date.new(2018, 1, 1) }
  let(:from_time) { Date.new(2019, 1, 1) }
  let(:to_time) { Date.new(2019, 3, 31) }

  let(:first_dec_prev_year) { Date.new(2018, 12, 1) }
  let(:first_jan) { Date.new(2019, 1, 1) }
  let(:first_feb) { Date.new(2019, 2, 1) }
  let(:first_mar) { Date.new(2019, 3, 1) }

  let(:past_options) { { from_time: 1.year.ago, to_time: from_time.prev_day } }
  let(:current_options) { { from_time: from_time, to_time: to_time } }

  before do
    # old patients recorded as hypertensive
    old_patients = Timecop.travel(one_year_ago) do
      old_patients = create_list(:patient, 5)
      old_patients.each { |patient| create(:blood_pressure, :high, patient: patient) }
      old_patients
    end

    Timecop.travel(from_time - ControlRateQuery::COHORT_DELTA) do
      # old patients recorded as hypertensive in cohort
      old_patients.each { |patient| create(:blood_pressure, :high, patient: patient) }
    end

    # newly enrolled patients each month
    [first_jan, first_feb, first_mar].each do |first_of_month|
      Timecop.travel(first_of_month) do
        patients = create_list(:patient, 5)
        patients.each do |patient|
          create(:blood_pressure,
                 :under_control,
                 patient: patient,
                 recorded_at: patient.device_created_at,
                 device_created_at: patient.device_created_at)
        end
      end
    end

    # returning patients
    Timecop.travel(from_time) do
      returning_patients = old_patients.take(2)
      create(:blood_pressure, :high, patient: returning_patients.first, recorded_at: Time.now)
      create(:blood_pressure, :under_control, patient: returning_patients.second, recorded_at: Time.now)
    end

    # retro-actively added blood_pressures
    Timecop.travel(first_feb) do
      returning_patients = old_patients.take(2)
      create(:blood_pressure, :high, patient: returning_patients.first, recorded_at: 1.week.ago)
      create(:blood_pressure, :under_control, patient: returning_patients.second, recorded_at: 1.week.ago)
    end
  end

  let(:analytics) { Analytics::PatientSetAnalytics.new(Patient.all, from_time, to_time) }

  describe '#unique_patients_count' do
    it 'returns the number of unique patients in the list' do
      expect(analytics.unique_patients_count).to eq(20)
    end
  end

  describe '#newly_enrolled_patients_count' do
    it 'returns the number of patients newly enrolled in the period' do
      expect(analytics.newly_enrolled_patients_count).to eq(15)
    end
  end

  describe '#newly_enrolled_patients_count_per_month' do
    it 'returns the number of patients newly enrolled per month' do
      expect(analytics.newly_enrolled_patients_count_per_month(4))
        .to include(first_dec_prev_year => 0,
                    first_jan => 5,
                    first_feb => 5,
                    first_mar => 5)
    end
  end

  describe '#returning_patients_count' do
    it 'returns the number of patients that where recorded before from_time and have BP recording in the give period' do
      expect(analytics.returning_patients_count).to eq(2)
    end
  end

  describe '#non_returning_hypertensive_patients_count' do
    it 'return the number of patients enrolled as hypertensives that have not had a BP recorded in the period' do
      expect(analytics.non_returning_hypertensive_patients_count).to eq(3)
    end
  end

  describe '#non_returning_hypertensive_patients_count_per_month' do
    it 'return the number of patients enrolled as hypertensives that have not had a BP recorded per month' do
      expect(analytics.non_returning_hypertensive_patients_count_per_month(4))
        .to eq(first_dec_prev_year => 3,
               first_jan => 3,
               first_feb => 4,
               first_mar => 4)
    end
  end

  describe '#blood_pressure_recored_per_week' do
    it 'returns the number of blood pressures recorded per week for a group of patients' do
      expected_counts = {
        Date.new(2019, 1, 06) => 0,
        Date.new(2019, 1, 13) => 0,
        Date.new(2019, 1, 20) => 2,
        Date.new(2019, 1, 27) => 5,
        Date.new(2019, 2, 03) => 0,
        Date.new(2019, 2, 10) => 0,
        Date.new(2019, 2, 17) => 0,
        Date.new(2019, 2, 24) => 5,
        Date.new(2019, 3, 03) => 0,
        Date.new(2019, 3, 10) => 0,
        Date.new(2019, 3, 17) => 0,
        Date.new(2019, 3, 24) => 0,
        Date.new(2019, 3, 31) => 0,
      }

      expect(analytics.blood_pressures_recorded_per_week(12)).to eq(expected_counts)
    end
  end

  context "control rate queries" do
    before do
      cohort_patients = []

      Timecop.travel(from_time - ControlRateQuery::COHORT_DELTA) do
        # newly enrolled patients in the cohort
        cohort_patients = create_list(:patient, 5)
        cohort_patients.each { |patient| create(:blood_pressure, :high, patient: patient) }
      end

      Timecop.travel(from_time) do
        # returning patients from the earlier cohort
        create(:blood_pressure, :high, patient: cohort_patients.first)
        create(:blood_pressure, :under_control, patient: cohort_patients.second)
      end
    end

    describe '#control_rate' do
      context 'number of patients now under control / number of hypertensives patients recorded in cohort' do
        it 'returns the control rate for the set of patients in the period' do
          expect(analytics.control_rate)
            .to eq(control_rate: 20,
                   hypertensive_patients_in_cohort: 5,
                   patients_under_control_in_period: 1)
        end
      end
    end

    describe '#control_rate_per_month' do
      it 'returns the number of blood pressures recorded per week for a group of patients' do
        expected_counts = {
          Date.new(2018, 10, 1) => 0,
          Date.new(2018, 11, 1) => 0,
          Date.new(2018, 12, 1) => 0,
          Date.new(2019, 1, 1) => 20,
          Date.new(2019, 2, 1) => 0,
          Date.new(2019, 3, 1) => 0,
        }

        expect(analytics.control_rate_per_month(6)).to eq(expected_counts)
      end
    end
  end
end
