require 'rails_helper'

RSpec.describe AppointmentNotificationService do
  context '#send_after_missed_visit' do
    let!(:user) { create(:user) }
    let!(:facility_1) { create(:facility) }
    let!(:facility_2) { create(:facility) }
    let!(:overdue_appointments_from_facility_1) { create_list(:appointment, 10, :overdue, facility: facility_1) }
    let!(:overdue_appointments_from_facility_2) { create_list(:appointment, 10, :overdue, facility: facility_2) }
    let!(:overdue_appointments) { overdue_appointments_from_facility_1 + overdue_appointments_from_facility_2 }
    let!(:recently_overdue_appointments) do
      create_list(:appointment,
                  10,
                  facility: facility_1,
                  scheduled_date: 1.day.ago,
                  status: :scheduled)
    end

    before do
      allow(ENV).to receive(:fetch).and_call_original

      @sms_response_double = double('SmsNotificationServiceResponse')
      allow_any_instance_of(SmsNotificationService).to receive(:send_reminder_sms).and_return(@sms_response_double)
      allow(@sms_response_double).to receive(:sid).and_return(SecureRandom.uuid)
      allow(@sms_response_double).to receive(:status).and_return('queued')
    end

    it 'should spawn sms reminder jobs' do
      AppointmentNotificationService.new(user).send_after_missed_visit(schedule_at: Time.now)
      assert_equal 1, AppointmentNotification::Worker.jobs.size
    end

    it 'should send sms reminders to eligible overdue appointments' do
      AppointmentNotificationService.new(user).send_after_missed_visit(schedule_at: Time.now)
      AppointmentNotification::Worker.drain

      eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments.count).to eq(20)
    end

    it 'should ignore appointments which are recently overdue (< 3 days)' do
      AppointmentNotificationService.new(user).send_after_missed_visit(schedule_at: Time.now)
      AppointmentNotification::Worker.drain

      ineligible_appointments = recently_overdue_appointments.select { |a| a.communications.present? }
      expect(ineligible_appointments).to be_empty
    end

    it 'should skip sending reminders for appointments for which reminders are already sent' do
      AppointmentNotificationService.new(user).send_after_missed_visit(schedule_at: Time.now)
      AppointmentNotification::Worker.drain

      eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments).to_not be_empty

      expect {
        AppointmentNotificationService.new(user).send_after_missed_visit(schedule_at: Time.now)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(0)
    end

    it 'should send reminders for appointments for which previous reminders failed' do
      allow(@sms_response_double).to receive(:status).and_return('failed')

      AppointmentNotificationService.new(user).send_after_missed_visit(schedule_at: Time.now)
      AppointmentNotification::Worker.drain

      eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments).to_not be_empty

      expect {
        AppointmentNotificationService.new(user).send_after_missed_visit(schedule_at: Time.now)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(1)
    end

    it 'should only send reminders for appointments under whitelisted facilities' do
      allow(ENV).to receive(:fetch).with('APPOINTMENT_NOTIFICATION_FACILITY_IDS').and_return(facility_1.id)

      expect {
        AppointmentNotificationService.new(user).send_after_missed_visit(schedule_at: Time.now)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(1)
    end

    it 'should only spawn half the jobs if the rollout percentage is 50%' do
      allow(ENV).to receive(:fetch).with('APPOINTMENT_NOTIFICATION_ROLLOUT_PERCENTAGE').and_return('50')

      expect {
        AppointmentNotificationService.new(user).send_after_missed_visit(schedule_at: Time.now)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(1)

      AppointmentNotification::Worker.drain

      eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments.count).to eq(10)
    end
  end
end
