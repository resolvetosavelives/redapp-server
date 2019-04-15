require 'rails_helper'

describe Appointment, type: :model do
  subject(:appointment) { create(:appointment) }

  describe 'Associations' do
    it { should belong_to(:patient) }
    it { should belong_to(:facility) }
    it { should have_many(:communications) }
  end

  context 'Validations' do
    it_behaves_like 'a record that validates device timestamps'
  end

  context 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end

  context 'Scopes' do
    describe '.overdue' do
      let(:overdue_appointment) { create(:appointment, :overdue) }
      let(:upcoming_appointment) { create(:appointment) }

      it "includes overdue appointments" do
        expect(Appointment.overdue).to include(overdue_appointment)
      end

      it "excludes non-overdue appointments" do
        expect(Appointment.overdue).not_to include(upcoming_appointment)
      end
    end
  end

  context "Result of follow-up" do
    describe "For each category in the follow-up options" do
      it "correctly records agreed to visit" do
        appointment.mark_patient_agreed_to_visit

        expect(appointment.agreed_to_visit).to eq(true)
        expect(appointment.remind_on).to eq(30.days.from_now.to_date)
      end

      it "correctly records that the patient has already visited" do
        appointment.mark_patient_already_visited

        expect(appointment.status).to eq('visited')
        expect(appointment.agreed_to_visit).to be nil
        expect(appointment.remind_on).to be nil
      end

      it "correctly records remind to call" do
        appointment.mark_remind_to_call_later

        expect(appointment.remind_on).to eq(7.days.from_now.to_date)
      end

      Appointment.cancel_reasons.values.each do |cancel_reason|
        it "correctly records cancel reason: '#{cancel_reason}'" do
          appointment.mark_appointment_cancelled(cancel_reason)

          expect(appointment.cancel_reason).to eq(cancel_reason)
          expect(appointment.status).to eq("cancelled")
        end
      end

      it "sets patient status if call indicated they died" do
        appointment.mark_patient_as_dead

        expect(appointment.patient.status).to eq("dead")
      end
    end
  end

  context 'Overdue' do
    describe '#overdue_for_over_a_year?' do
      it 'should return true if appointment is overdue for over a year' do
        appointment = create(:appointment, scheduled_date: 2.years.ago, status: :scheduled)

        expect(appointment.overdue_for_over_a_year?).to eq(true)
      end

      it 'should return false if appointment is overdue for less than a year' do
        appointment = create(:appointment, scheduled_date: 364.days.ago, status: :scheduled)

        expect(appointment.overdue_for_over_a_year?).to eq(false)
      end
    end

    describe '#overdue_for_under_a_month?' do
      it 'should return true if appointment is overdue for less than a month' do
        appointment = create(:appointment, scheduled_date: 29.days.ago, status: :scheduled)

        expect(appointment.overdue_for_under_a_month?).to eq(true)
      end

      it 'should return false if appointment is overdue for more than a month' do
        appointment = create(:appointment, scheduled_date: 31.days.ago, status: :scheduled)

        expect(appointment.overdue_for_under_a_month?).to eq(false)
      end
    end
  end

  context "CSV export" do
    describe ".csv_headers" do
      it "returns the correct headers" do
        headers = [
          "Patient name",
          "Gender",
          "Age",
          "Days overdue",
          "Last BP",
          "Last BP taken at",
          "Last BP date",
          "Risk level",
          "Patient address",
          "Patient village or colony",
          "Patient phone"
        ]
        expect(Appointment.csv_headers).to eq(headers)
      end
    end

    describe "#csv_fields" do
      before do
        create(:blood_pressure, :high, patient: appointment.patient)
      end

      it "returns the correct fields" do
        csv_fields = [
          appointment.patient.full_name,
          appointment.patient.gender.capitalize,
          appointment.patient.current_age,
          appointment.days_overdue,
          appointment.patient.latest_blood_pressure.to_s,
          appointment.patient.latest_blood_pressure.facility.name,
          appointment.patient.latest_blood_pressure.device_created_at.to_date,
          appointment.patient.risk_priority_label,
          appointment.patient.address.street_address,
          appointment.patient.address.village_or_colony,
          appointment.patient.phone_numbers.first&.number
        ]

        expect(appointment.csv_fields).to eq(csv_fields)
      end
    end
  end
end
