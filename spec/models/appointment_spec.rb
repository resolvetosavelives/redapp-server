require "rails_helper"

describe Appointment, type: :model do
  subject(:appointment) { create(:appointment) }

  describe "Associations" do
    it { should belong_to(:patient).optional }
    it { should belong_to(:facility) }
    it { should have_many(:notifications) }
  end

  context "Validations" do
    it_behaves_like "a record that validates device timestamps"
    it { should validate_presence_of(:appointment_type) }
  end

  context "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  context "Scopes" do
    describe ".between" do
      let(:old_appointment) { create(:appointment, scheduled_date: 3.days.ago) }
      let(:current_appointment) { create(:appointment, scheduled_date: 1.day.ago) }
      let(:future_appointment) { create(:appointment, scheduled_date: 1.day.from_now) }

      it "only includes the appointments scheduled during the provided date range" do
        appointments = Appointment.between(2.days.ago, Date.current)
        expect(appointments).to include(current_appointment)
        expect(appointments).not_to include(old_appointment)
        expect(appointments).not_to include(future_appointment)
      end
    end

    describe ".passed_unvisited" do
      it "includes all unvisited passed appointments" do
        past = 1.month.ago
        future = 1.month.from_now
        facility = create(:facility)
        user = create(:user, registration_facility: facility)
        patient = create(:patient, registration_facility: facility, registration_user: user)
        params = {facility_id: facility.id, creation_facility_id: facility.id, user: user, patient: patient}

        scheduled_past = create(:appointment, status: :scheduled, scheduled_date: past, **params)
        scheduled_future = create(:appointment, status: :scheduled, scheduled_date: future, **params)
        visited = create(:appointment, status: :visited, scheduled_date: past, **params)
        cancelled_past = create(:appointment, status: :cancelled, scheduled_date: past, **params)
        cancelled_future = create(:appointment, status: :cancelled, scheduled_date: future, **params)
        appointment_to_remind = create(:appointment, status: :scheduled, scheduled_date: past, remind_on: future, **params)

        expect(described_class.passed_unvisited).to include(scheduled_past, cancelled_past, appointment_to_remind)
        expect(described_class.passed_unvisited).not_to include(scheduled_future, cancelled_future, visited)
      end
    end

    describe ".last_year_unvisited" do
      it "only includes unvisited appointments from the last year" do
        facility = create(:facility)
        user = create(:user, registration_facility: facility)
        patient = create(:patient, registration_facility: facility, registration_user: user)
        params = {facility_id: facility.id, creation_facility_id: facility.id, user: user, patient: patient}

        scheduled_in_last_year = create(:appointment, status: :scheduled, scheduled_date: 1.month.ago, **params)
        scheduled_before_last_year = create(:appointment, status: :scheduled, scheduled_date: 2.year.ago, **params)

        expect(described_class.last_year_unvisited).to include(scheduled_in_last_year)
        expect(described_class.last_year_unvisited).not_to include(scheduled_before_last_year)
      end
    end

    describe ".all_overdue" do
      it "includes only scheduled passed appointments" do
        past = 1.month.ago
        future = 1.month.from_now
        facility = create(:facility)
        user = create(:user, registration_facility: facility)
        patient = create(:patient, registration_facility: facility, registration_user: user)
        params = {facility_id: facility.id, creation_facility_id: facility.id, user: user, patient: patient}

        scheduled_past = create(:appointment, status: :scheduled, scheduled_date: past, **params)
        scheduled_future = create(:appointment, status: :scheduled, scheduled_date: future, **params)
        visited = create(:appointment, status: :visited, scheduled_date: past, **params)
        cancelled_past = create(:appointment, status: :cancelled, scheduled_date: past, **params)
        cancelled_future = create(:appointment, status: :cancelled, scheduled_date: future, **params)
        appointment_to_remind = create(:appointment, status: :scheduled, scheduled_date: past, remind_on: future, **params)

        expect(described_class.all_overdue).to include(scheduled_past)
        expect(described_class.all_overdue.map(&:id)).not_to include([scheduled_future, cancelled_future, visited, cancelled_past, appointment_to_remind].map(&:id))
      end
    end

    describe ".overdue" do
      let(:overdue_appointment) { create(:appointment, :overdue) }
      let(:upcoming_appointment) { create(:appointment) }

      it "includes overdue appointments" do
        expect(Appointment.overdue).to include(overdue_appointment)
      end

      it "excludes non-overdue appointments" do
        expect(Appointment.overdue).not_to include(upcoming_appointment)
      end
    end

    describe ".overdue_by" do
      let(:recently_overdue_appointment) { create(:appointment, scheduled_date: 2.days.ago, status: :scheduled) }
      let(:overdue_appointment) { create(:appointment, :overdue) }
      let(:upcoming_appointment) { create(:appointment) }

      it "includes overdue appointments that are overdue by 3 or more days" do
        expect(Appointment.overdue_by(3)).not_to include(recently_overdue_appointment)
        expect(Appointment.overdue_by(3)).to include(overdue_appointment)
      end

      it "excludes non-overdue appointments" do
        expect(Appointment.overdue).not_to include(upcoming_appointment)
      end
    end

    describe "#follow_up_days" do
      let(:appointment) { create(:appointment, scheduled_date: 30.days.ago, device_created_at: 40.days.ago) }

      specify { expect(appointment.follow_up_days).to eq(10) }
    end

    describe ".eligible_for_reminders" do
      it "includes only appointments overdue by at least days_overdue" do
        _not_overdue = create(:appointment, scheduled_date: 2.days.ago, status: :scheduled)
        overdue = create(:appointment, scheduled_date: 3.days.ago, status: :scheduled)
        more_overdue = create(:appointment, scheduled_date: 4.days.ago, status: :scheduled)

        expect(described_class.eligible_for_reminders(days_overdue: 3)).to match_array([overdue, more_overdue])
      end

      it "excludes appointments that have appointment reminders" do
        overdue_appointment = create(:appointment, scheduled_date: 3.days.ago, status: :scheduled)
        create(:notification, subject: overdue_appointment)

        expect(described_class.eligible_for_reminders(days_overdue: 3)).to be_empty
      end

      it "excludes appointments that have communications" do
        overdue_appointment = create(:appointment, scheduled_date: 3.days.ago, status: :scheduled)
        notification = create(:notification, subject: overdue_appointment)
        create(:communication, notification: notification)

        expect(described_class.eligible_for_reminders(days_overdue: 3)).to be_empty
      end

      context "for patients marked as dead" do
        let!(:patient) { create(:patient, status: "dead") }
        let!(:appointment) { create(:appointment, :overdue, patient: patient, scheduled_date: 3.days.ago) }

        it "excludes appointments" do
          expect(described_class.eligible_for_reminders(days_overdue: 3)).not_to include appointment
        end
      end

      context "for patients who have denied consent" do
        let!(:patient) { create(:patient, :denied) }
        let!(:appointment) { create(:appointment, :overdue, patient: patient, scheduled_date: 3.days.ago) }

        it "excludes appointments" do
          expect(described_class.eligible_for_reminders(days_overdue: 3)).not_to include appointment
        end
      end

      it "only includes appointments with mobile numbers" do
        mobile_number = create(:patient_phone_number, phone_type: :mobile)
        landline_number = create(:patient_phone_number, phone_type: :landline)
        invalid_number = create(:patient_phone_number, phone_type: :invalid)

        patient_with_mobile = create(:patient, phone_numbers: [mobile_number, invalid_number])
        patient_with_landline = create(:patient, phone_numbers: [landline_number])

        appointment_with_mobile =
          create(:appointment, :overdue, patient: patient_with_mobile, scheduled_date: 3.days.ago)
        appointment_with_landline =
          create(:appointment, :overdue, patient: patient_with_landline, scheduled_date: 3.days.ago)

        expect(described_class.eligible_for_reminders(days_overdue: 3)).to include appointment_with_mobile
        expect(described_class.eligible_for_reminders(days_overdue: 3)).not_to include appointment_with_landline
      end

      it "only includes appointments with phone numbers" do
        patient_with_no_number = create(:patient, phone_numbers: [])
        _appointment_with_no_number =
          create(:appointment, :overdue, patient: patient_with_no_number, scheduled_date: 3.days.ago)

        expect(described_class.eligible_for_reminders(days_overdue: 3)).to be_empty
      end
    end

    describe ".for_sync" do
      it "includes discarded appointments" do
        discarded_appointment = create(:appointment, deleted_at: Time.now)

        expect(described_class.for_sync).to include(discarded_appointment)
      end
    end
  end

  context "For discarded patients" do
    let!(:discard_patient) { create(:patient) }
    let!(:overdue_appointment) { create(:appointment, :overdue) }
    let!(:discarded_overdue_appointment) { create(:appointment, :overdue, patient: discard_patient) }

    it "shouldn't include discarded patients' appointments " do
      discard_patient.discard_data

      expect(Appointment.overdue).to include(overdue_appointment)
      expect(Appointment.overdue).not_to include(discarded_overdue_appointment)
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

        expect(appointment.status).to eq("visited")
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
    end

    describe "#update_patient_status" do
      it "updates patient status if appointment call result is marked as dead" do
        appointment.update(cancel_reason: :dead)
        appointment.update_patient_status
        expect(appointment.patient.status).to eq "dead"
      end

      it "updates patient status if appointment call result is marked as moved_to_private" do
        appointment.update(cancel_reason: :moved_to_private)
        appointment.update_patient_status
        expect(appointment.patient.status).to eq "migrated"
      end

      it "updates patient status if appointment call result is marked as public_hospital_transfer" do
        appointment.update(cancel_reason: :public_hospital_transfer)
        appointment.update_patient_status
        expect(appointment.patient.status).to eq "migrated"
      end
    end
  end

  context "Overdue" do
    describe "#days_overdue" do
      it "returns the number of days overdue" do
        appointment = create(:appointment, scheduled_date: 60.days.ago, status: :scheduled)
        expect(appointment.days_overdue).to eq(60)
      end

      it "returns zero if the appointment is not overdue" do
        appointment = create(:appointment, scheduled_date: 10.days.from_now, status: :scheduled)
        expect(appointment.days_overdue).to eq(0)
      end
    end

    describe "#overdue_for_over_a_year?" do
      it "should return true if appointment is overdue for over a year" do
        appointment = create(:appointment, scheduled_date: 2.years.ago, status: :scheduled)

        expect(appointment.overdue_for_over_a_year?).to eq(true)
      end

      it "should return false if appointment is overdue for less than a year" do
        appointment = create(:appointment, scheduled_date: 364.days.ago, status: :scheduled)

        expect(appointment.overdue_for_over_a_year?).to eq(false)
      end
    end

    describe "#overdue_for_under_a_month?" do
      it "should return true if appointment is overdue for less than a month" do
        appointment = create(:appointment, scheduled_date: 29.days.ago, status: :scheduled)

        expect(appointment.overdue_for_under_a_month?).to eq(true)
      end

      it "should return false if appointment is overdue for more than a month" do
        appointment = create(:appointment, scheduled_date: 31.days.ago, status: :scheduled)

        expect(appointment.overdue_for_under_a_month?).to eq(false)
      end
    end
  end

  describe "#previously_communicated_via" do
    let(:overdue_appointment) do
      create(:appointment,
        scheduled_date: 31.days.ago,
        status: :scheduled)
    end

    it "returns falsey if there are no communications for the appointment" do
      expect(overdue_appointment.previously_communicated_via?(:sms)).to be_falsey
    end

    it "returns falsey if there are non sms communications for the appointment" do
      notification = create(:notification, subject: overdue_appointment)
      create(:communication,
        communication_type: :voip_call,
        appointment: overdue_appointment,
        notification: notification)

      expect(overdue_appointment.previously_communicated_via?(:sms)).to be_falsey
    end

    it "returns true if followup reminder SMS for the appointment was unsuccessful" do
      notification = create(:notification, subject: overdue_appointment)
      notification.communications << create(:communication,
        :sms,
        appointment: overdue_appointment,
        detailable: create(:twilio_sms_delivery_detail, :undelivered))

      expect(overdue_appointment.previously_communicated_via?(:sms)).to eq(false)
    end

    it "returns false if followup reminder SMS for the appointment were successful" do
      notification = create(:notification, subject: overdue_appointment)
      notification.communications << create(:communication,
        :sms,
        appointment_id: overdue_appointment.id,
        notification: notification,
        detailable: create(:twilio_sms_delivery_detail, :delivered))

      expect(overdue_appointment.reload.previously_communicated_via?(:sms)).to eq(true)
    end
  end

  context "anonymised data for appointments" do
    describe "anonymized_data" do
      it "correctly retrieves the anonymised data for an appointment" do
        anonymised_data =
          {
            id: Hashable.hash_uuid(appointment.id),
            patient_id: Hashable.hash_uuid(appointment.patient_id),
            created_at: appointment.created_at,
            registration_facility_name: appointment.facility.name,
            user_id: Hashable.hash_uuid(appointment.patient.registration_user.id),
            scheduled_date: appointment.scheduled_date,
            overdue: appointment.days_overdue > 0 ? "Yes" : "No",
            status: appointment.status,
            agreed_to_visit: appointment.agreed_to_visit,
            remind_on: appointment.remind_on
          }

        expect(appointment.anonymized_data).to eq anonymised_data
      end
    end
  end

  describe "appointment reminder cancellation" do
    it "does not cancel reminders when appointment status is changed to 'scheduled'" do
      appointment.update!(status: nil)
      reminder = create(:notification, subject: appointment, status: "pending")

      expect {
        appointment.update!(status: "scheduled")
      }.not_to change { reminder.reload.status }
    end

    it "cancels reminders when an appointment status is changed to 'visited'" do
      reminder = create(:notification, subject: appointment, status: "pending")

      expect {
        appointment.update!(status: "visited")
      }.to change { reminder.reload.status }.from("pending").to("cancelled")
    end

    it "cancels reminders when an appointment status is changed to 'cancelled'" do
      reminder = create(:notification, subject: appointment, status: "pending")

      expect {
        appointment.update!(status: "cancelled")
      }.to change { reminder.reload.status }.from("pending").to("cancelled")
    end

    it "does not cancel sent reminders" do
      reminder = create(:notification, subject: appointment, status: "sent")

      expect {
        appointment.update!(status: "visited")
      }.not_to change { reminder.reload.status }
    end
  end
end
