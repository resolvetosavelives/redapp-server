require "rails_helper"

describe MaterializedPatientSummary, type: :model do
  include QuarterHelper

  describe "View" do
    subject(:patient_summary) { MaterializedPatientSummary.find(patient.id) }

    let(:old_date) { DateTime.new(2019, 1, 1) }
    let(:new_date) { DateTime.new(2019, 5, 1) }
    let(:old_quarter) { "2019 Q1" }
    let(:new_quarter) { "2019 Q2" }
    let!(:patient) { create(:patient, recorded_at: old_date) }
    let!(:old_phone) { create(:patient_phone_number, patient: patient, device_created_at: old_date) }
    let!(:new_phone) { create(:patient_phone_number, patient: patient, device_created_at: new_date) }
    let!(:old_bp) { create(:blood_pressure, patient: patient, recorded_at: old_date) }
    let!(:new_bp) { create(:blood_pressure, patient: patient, recorded_at: new_date, systolic: 110, diastolic: 70) }
    let!(:new_bs) { create(:blood_sugar, patient: patient, recorded_at: new_date, blood_sugar_type: "random", blood_sugar_value: 100) }
    let!(:old_passport) { create(:patient_business_identifier, patient: patient, device_created_at: old_date) }
    let!(:next_appointment) { create(:appointment, patient: patient) }
    let(:med_history) { create(:medical_history, patient: patient) }

    def refresh_view
      MaterializedPatientSummary.refresh
    end

    before { refresh_view }

    describe "Associations" do
      it { is_expected.to have_many(:appointments) }
      it { is_expected.to have_many(:prescription_drugs) }
      it { is_expected.to have_many(:current_prescription_drugs) }
      it { is_expected.to have_many(:latest_blood_pressures) }
    end

    describe "Scopes" do
      context ".overdue" do
        let!(:overdue_appointment) { create(:appointment, :overdue) }
        let!(:upcoming_appointment) { create(:appointment) }

        before { refresh_view }

        it "includes overdue appointments" do
          expect(MaterializedPatientSummary.overdue.map(&:id)).to include(overdue_appointment.patient_id)
        end

        it "excludes non-overdue appointments" do
          expect(MaterializedPatientSummary.overdue.map(&:id)).not_to include(upcoming_appointment.patient_id)
        end
      end
    end

    describe "Patient details" do
      it "uses the same ID as patient" do
        expect(patient_summary.id).to eq(patient.id)
      end

      it "includes patient attributes" do
        expect(patient_summary.full_name).to eq(patient.full_name)
        expect(patient_summary.gender).to eq(patient.gender)
        expect(patient_summary.status).to eq(patient.status)
      end

      context "current_age" do
        it "uses DOB as current age if present" do
          date_of_birth = 40.years.ago
          patient.update(date_of_birth: date_of_birth)
          refresh_view

          expect(patient_summary.current_age).to eq(40)
        end

        it "calculates current_age if DOB is not present" do
          patient.update(date_of_birth: nil, age: 50, age_updated_at: 13.months.ago)
          refresh_view

          expect(patient_summary.current_age).to eq(51)
        end
      end

      it "includes patient address", :aggregate_failures do
        expect(patient_summary.village_or_colony).to eq(patient.address.village_or_colony)
        expect(patient_summary.district).to eq(patient.address.district)
        expect(patient_summary.state).to eq(patient.address.state)
      end
    end

    describe "Registration details" do
      it "includes registration date" do
        expect(patient_summary.recorded_at).to eq(old_date)
      end

      it "calculates registration quarter" do
        expect(patient_summary.registration_quarter).to eq(old_quarter)
      end

      it "includes registration facility details", :aggregate_failures do
        expect(patient_summary.registration_facility_name).to eq(patient.registration_facility.name)
        expect(patient_summary.registration_facility_type).to eq(patient.registration_facility.facility_type)
        expect(patient_summary.registration_district).to eq(patient.registration_facility.district)
        expect(patient_summary.registration_state).to eq(patient.registration_facility.state)
      end
    end

    describe "Latest BP reading" do
      it "includes latest BP measurements", :aggregate_failures do
        expect(patient_summary.latest_blood_pressure_systolic).to eq(new_bp.systolic)
        expect(patient_summary.latest_blood_pressure_diastolic).to eq(new_bp.diastolic)
      end

      it "includes latest BP date" do
        expect(patient_summary.latest_blood_pressure_recorded_at).to eq(new_bp.recorded_at)
      end

      it "includes latest BP quarter" do
        expect(patient_summary.latest_blood_pressure_quarter).to eq(new_quarter)
      end

      it "includes latest BP facility details", :aggregate_failures do
        expect(patient_summary.latest_blood_pressure_facility_name).to eq(new_bp.facility.name)
        expect(patient_summary.latest_blood_pressure_facility_type).to eq(new_bp.facility.facility_type)
        expect(patient_summary.latest_blood_pressure_district).to eq(new_bp.facility.district)
        expect(patient_summary.latest_blood_pressure_state).to eq(new_bp.facility.state)
      end
    end

    describe "Latest Blood Sugar reading" do
      it "includes latest BS measurements", :aggregate_failures do
        expect(patient_summary.latest_blood_sugar_type).to eq(new_bs.blood_sugar_type)
        expect(patient_summary.latest_blood_sugar_value).to eq(new_bs.blood_sugar_value)
      end

      it "includes latest BS date" do
        expect(patient_summary.latest_blood_sugar_recorded_at).to eq(new_bs.recorded_at)
      end

      it "includes latest BS quarter" do
        expect(patient_summary.latest_blood_sugar_quarter).to eq(new_quarter)
      end

      it "includes latest BS facility details", :aggregate_failures do
        expect(patient_summary.latest_blood_sugar_facility_name).to eq(new_bs.facility.name)
        expect(patient_summary.latest_blood_sugar_facility_type).to eq(new_bs.facility.facility_type)
        expect(patient_summary.latest_blood_sugar_district).to eq(new_bs.facility.district)
        expect(patient_summary.latest_blood_sugar_state).to eq(new_bs.facility.state)
      end
    end

    describe "Next appointment details" do
      context "days_overdue" do
        it "set to zero if not overdue" do
          expect(patient_summary.days_overdue).to eq(0)
        end

        it "calculated if overdue" do
          next_appointment.update(scheduled_date: 60.days.ago)
          refresh_view

          expect(patient_summary.reload.days_overdue).to eq(60)
        end
      end

      it "includes next appointment date" do
        expect(patient_summary.next_scheduled_appointment_scheduled_date).to eq(next_appointment.scheduled_date)
      end

      it "includes latest BP facility details", :aggregate_failures do
        expect(patient_summary.next_scheduled_appointment_facility_name).to eq(next_appointment.facility.name)
        expect(patient_summary.next_scheduled_appointment_facility_type).to eq(next_appointment.facility.facility_type)
        expect(patient_summary.next_scheduled_appointment_district).to eq(next_appointment.facility.district)
        expect(patient_summary.next_scheduled_appointment_state).to eq(next_appointment.facility.state)
      end
    end

    describe "Risk level" do
      describe "#risk_priority" do
        before { Appointment.destroy_all }
        it "returns 0 for patients recently overdue" do
          create(:appointment, scheduled_date: 29.days.ago, status: :scheduled, patient: patient)
          refresh_view

          expect(MaterializedPatientSummary.find_by(id: patient.id).risk_level).to eq(0)
        end

        it "returns 1 for patients overdue with critical bp" do
          create(:blood_pressure, :critical, patient: patient)
          create(:appointment, scheduled_date: 31.days.ago, status: :scheduled, patient: patient)
          refresh_view

          expect(MaterializedPatientSummary.find_by(id: patient.id).risk_level).to eq(1)
        end

        it "returns 1 for hypertensive bp patients with medical history risks" do
          patient.medical_history.delete
          create(:medical_history, :prior_risk_history, patient: patient)
          create(:blood_pressure, :hypertensive, patient: patient)
          create(:appointment, :overdue, patient: patient)
          refresh_view

          expect(MaterializedPatientSummary.find_by(id: patient.id).risk_level).to eq(1)
        end

        it "returns 0 for patients overdue with only hypertensive bp" do
          create(:blood_pressure, :hypertensive, patient: patient)
          create(:appointment, :overdue, patient: patient)
          refresh_view

          expect(MaterializedPatientSummary.find_by(id: patient.id).risk_level).to eq(0)
        end

        it "returns 0 for patients overdue with only medical risk history" do
          create(:medical_history, :prior_risk_history, patient: patient)
          create(:appointment, :overdue, patient: patient)
          refresh_view

          expect(MaterializedPatientSummary.find_by(id: patient.id).risk_level).to eq(0)
        end

        it "returns 0 for patients overdue with hypertension" do
          create(:blood_pressure, :hypertensive, patient: patient)
          create(:appointment, :overdue, patient: patient)
          refresh_view

          expect(MaterializedPatientSummary.find_by(id: patient.id).risk_level).to eq(0)
        end

        it "returns 0 for patients overdue with low risk" do
          create(:blood_pressure, :under_control, patient: patient)
          create(:appointment, scheduled_date: 2.years.ago, status: :scheduled, patient: patient)
          refresh_view

          expect(MaterializedPatientSummary.find_by(id: patient.id).risk_level).to eq(0)
        end

        it "returns 1 for patients overdue with high blood sugar" do
          create(:blood_sugar, patient: patient, blood_sugar_type: :random, blood_sugar_value: 300)
          create(:appointment, scheduled_date: 31.days.ago, status: :scheduled, patient: patient)
          refresh_view

          expect(MaterializedPatientSummary.find_by(id: patient.id).risk_level).to eq(1)
        end

        it "returns 'none' priority for patients overdue with normal blood sugar" do
          create(:blood_sugar, patient: patient, blood_sugar_type: :random, blood_sugar_value: 150)
          create(:appointment, :overdue, patient: patient)
          refresh_view

          expect(MaterializedPatientSummary.find_by(id: patient.id).risk_level).to eq(0)
        end
      end
    end

    describe "BP passport" do
      it "includes latest BP passport" do
        expect(patient_summary.latest_bp_passport).to eq(patient.latest_bp_passport)
      end

      it "includes latest BP passport number directly" do
        expect(patient_summary.latest_bp_passport_identifier).to eq(patient.latest_bp_passport.identifier)
      end
    end

    describe "#ltfu?" do
      specify do
        ltfu_patient = create(:patient, recorded_at: 2.years.ago)
        refresh_view

        expect(described_class.find_by(id: ltfu_patient.id).ltfu?).to eq true
      end

      specify do
        not_ltfu_patient = create(:patient, recorded_at: 1.month.ago)
        refresh_view

        expect(described_class.find_by(id: not_ltfu_patient.id).ltfu?).to eq false
      end
    end
  end
end
