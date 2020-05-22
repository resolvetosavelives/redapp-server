require 'rails_helper'
include Hashable

describe Appointment, type: :model do
  subject(:appointment) { create(:appointment) }

  describe 'Associations' do
    it { should belong_to(:patient).optional }
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

      it 'includes overdue appointments' do
        expect(Appointment.overdue).to include(overdue_appointment)
      end

      it 'excludes non-overdue appointments' do
        expect(Appointment.overdue).not_to include(upcoming_appointment)
      end
    end

    describe '.overdue_by' do
      let(:recently_overdue_appointment) { create(:appointment, scheduled_date: 2.days.ago, status: :scheduled) }
      let(:overdue_appointment) { create(:appointment, :overdue) }
      let(:upcoming_appointment) { create(:appointment) }

      it 'includes overdue appointments that are overdue by 3 or more days' do
        expect(Appointment.overdue_by(3)).not_to include(recently_overdue_appointment)
        expect(Appointment.overdue_by(3)).to include(overdue_appointment)
      end

      it 'excludes non-overdue appointments' do
        expect(Appointment.overdue).not_to include(upcoming_appointment)
      end
    end

    describe '.eligible_for_reminders' do
      let!(:dead_patient) { create(:patient, status: 'dead') }
      let!(:patient_with_consent_denied) { create(:patient, :denied) }
      let!(:overdue_appointment_for_dead_patient) do
        create(:appointment, :overdue, patient: dead_patient, scheduled_date: 3.days.ago)
      end
      let!(:overdue_appointment_for_denied_patient) do
        create(:appointment, :overdue, patient: patient_with_consent_denied, scheduled_date: 3.days.ago)
      end
      let!(:recently_overdue_appointment) { create(:appointment, scheduled_date: 2.days.ago, status: :scheduled) }
      let!(:overdue_appointment) { create(:appointment, :overdue, scheduled_date: 3.days.ago) }

      specify { expect(Appointment.eligible_for_reminders(days_overdue: 3)).to contain_exactly overdue_appointment }
    end
  end

  context 'For discarded patients' do
    let!(:discard_patient) { create(:patient) }
    let!(:overdue_appointment) { create(:appointment, :overdue) }
    let!(:discarded_overdue_appointment) { create(:appointment, :overdue, patient: discard_patient) }

    it "shouldn't include discarded patients' appointments " do
      discard_patient.discard_data

      expect(Appointment.overdue).to include(overdue_appointment)
      expect(Appointment.overdue).not_to include(discarded_overdue_appointment)
    end
  end

  context 'Result of follow-up' do
    describe 'For each category in the follow-up options' do
      it 'correctly records agreed to visit' do
        appointment.mark_patient_agreed_to_visit

        expect(appointment.agreed_to_visit).to eq(true)
        expect(appointment.remind_on).to eq(30.days.from_now.to_date)
      end

      it 'correctly records that the patient has already visited' do
        appointment.mark_patient_already_visited

        expect(appointment.status).to eq('visited')
        expect(appointment.agreed_to_visit).to be nil
        expect(appointment.remind_on).to be nil
      end

      it 'correctly records remind to call' do
        appointment.mark_remind_to_call_later

        expect(appointment.remind_on).to eq(7.days.from_now.to_date)
      end

      Appointment.cancel_reasons.values.each do |cancel_reason|
        it "correctly records cancel reason: '#{cancel_reason}'" do
          appointment.mark_appointment_cancelled(cancel_reason)

          expect(appointment.cancel_reason).to eq(cancel_reason)
          expect(appointment.status).to eq('cancelled')
        end
      end

      it 'sets patient status if call indicated they died' do
        appointment.mark_patient_as_dead

        expect(appointment.patient.status).to eq('dead')
      end
    end
  end

  context 'Overdue' do
    describe '#days_overdue' do
      it 'returns the number of days overdue' do
        appointment = create(:appointment, scheduled_date: 60.days.ago, status: :scheduled)
        expect(appointment.days_overdue).to eq(60)
      end

      it 'returns zero if the appointment is not overdue' do
        appointment = create(:appointment, scheduled_date: 10.days.from_now, status: :scheduled)
        expect(appointment.days_overdue).to eq(0)
      end
    end

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

  describe '#previously_communicated_via' do
    let(:overdue_appointment) do
      create(:appointment,
             scheduled_date: 31.days.ago,
             status: :scheduled)
    end

    it 'returns falsey if there are no communications for the appointment' do
      expect(overdue_appointment.previously_communicated_via?(:missed_visit_sms_reminder)).to be_falsey
    end

    it 'returns falsey if there are non missed_visit_sms_reminder communications for the appointment' do
      create(:communication,
             communication_type: :voip_call,
             appointment: overdue_appointment)

      expect(overdue_appointment.previously_communicated_via?(:missed_visit_sms_reminder)).to be_falsey
    end

    it 'returns true if followup reminder SMS for the appointment was unsuccessful' do
      create(:communication,
             :missed_visit_sms_reminder,
             appointment: overdue_appointment,
             detailable: create(:twilio_sms_delivery_detail, :undelivered))

      expect(overdue_appointment.previously_communicated_via?(:missed_visit_sms_reminder)).to eq(false)
    end

    it 'returns false if followup reminder SMS for the appointment were successful' do
      create(:communication,
             :missed_visit_sms_reminder,
             appointment: overdue_appointment,
             detailable: create(:twilio_sms_delivery_detail, :delivered))

      expect(overdue_appointment.previously_communicated_via?(:missed_visit_sms_reminder)).to eq(true)
    end
  end

  context 'anonymised data for appointments' do
    describe 'anonymized_data' do
      it 'correctly retrieves the anonymised data for an appointment' do
        anonymised_data =
          { id: hash_uuid(appointment.id),
            patient_id: hash_uuid(appointment.patient_id),
            created_at: appointment.created_at,
            registration_facility_name: appointment.facility.name,
            user_id: hash_uuid(appointment.patient.registration_user.id),
            scheduled_date: appointment.scheduled_date,
            overdue: appointment.days_overdue > 0 ? 'Yes' : 'No',
            status: appointment.status,
            agreed_to_visit: appointment.agreed_to_visit,
            remind_on: appointment.remind_on }

        expect(appointment.anonymized_data).to eq anonymised_data
      end
    end
  end
end
