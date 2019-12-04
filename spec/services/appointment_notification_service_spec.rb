require 'rails_helper'

RSpec.describe AppointmentNotificationService do
  context '#send_after_missed_visit' do
    let!(:overdue_appointments) do
      overdue_appointment_ids = create_list(:appointment, 4, :overdue).map(&:id)
      Appointment.where(id: overdue_appointment_ids)
          .includes(patient: [:phone_numbers], facility: { facility_group: :organization })
    end

    let!(:recently_overdue_appointments) do
      recently_overdue_appointment_ids = create_list(:appointment, 2, scheduled_date: 1.day.ago, status: :scheduled).map(&:id)
      Appointment.where(id: recently_overdue_appointment_ids)
          .includes(patient: [:phone_numbers], facility: { facility_group: :organization })
    end

    before do
      @sms_response_double = double('SmsNotificationServiceResponse')
      allow_any_instance_of(SmsNotificationService).to receive(:send_reminder_sms).and_return(@sms_response_double)
      allow(@sms_response_double).to receive(:sid).and_return(SecureRandom.uuid)
      allow(@sms_response_double).to receive(:status).and_return('queued')
    end

    it 'should spawn sms reminder jobs' do
      expect {
        AppointmentNotificationService.new().send_after_missed_visit(appointments: overdue_appointments, schedule_at: Time.current)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(1)
    end

    it 'should ignore appointments which are recently overdue (< 3 days)' do
      AppointmentNotificationService.new().send_after_missed_visit(appointments: recently_overdue_appointments, days_overdue: 3, schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      ineligible_appointments = recently_overdue_appointments.select { |a| a.communications.present? }
      expect(ineligible_appointments).to be_empty
    end

    it 'should skip sending reminders for appointments for which reminders are already sent' do
      AppointmentNotificationService.new().send_after_missed_visit(appointments: overdue_appointments, schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      appointments_with_reminders_sent = overdue_appointments.select { |a| a.communications.present? }
      expect(appointments_with_reminders_sent.count).to eq(4)

      expect {
        AppointmentNotificationService.new().send_after_missed_visit(appointments: overdue_appointments, schedule_at: Time.current)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(0)
    end

    it 'should send reminders for appointments for which previous reminders failed' do
      allow(@sms_response_double).to receive(:status).and_return('failed')

      AppointmentNotificationService.new().send_after_missed_visit(appointments: overdue_appointments, schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      appointments_with_reminders_failed = overdue_appointments.select { |a| a.communications.any?(&:unsuccessful?) }
      expect(appointments_with_reminders_failed.count).to eq(4)

      expect {
        AppointmentNotificationService.new().send_after_missed_visit(appointments: overdue_appointments, schedule_at: Time.current)
      }.to change(AppointmentNotification::Worker.jobs, :size).by(1)
    end

    it 'should only send reminders to patients who have granted consent' do
      overdue_appointment_ids =
          [create(:patient), create(:patient, :denied)].map do |patient|
            create(:appointment, :overdue, patient: patient).id
          end

      overdue_appointments = Appointment.where(id: overdue_appointment_ids)
                                 .includes(patient: [:phone_numbers], facility: { facility_group: :organization })

      AppointmentNotificationService.new().send_after_missed_visit(appointments: overdue_appointments, schedule_at: Time.current)
      AppointmentNotification::Worker.drain

      eligible_appointments = overdue_appointments.select { |a| a.communications.present? }
      expect(eligible_appointments.count).to eq(1)
    end
  end
end
