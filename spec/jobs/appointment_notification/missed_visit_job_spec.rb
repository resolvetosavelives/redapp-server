require "rails_helper"

RSpec.describe AppointmentNotification::MissedVisitJob, type: :job do
  it "should do nothing if feature flag is off" do
    Flipper.disable(:appointment_reminders)
    expect_any_instance_of(AppointmentNotification::Worker).to receive(:perform).never
    described_class.perform_now
  end

  it "should send all appointments to notification service" do
    Flipper.enable(:appointment_reminders)
    create_list(:appointment, 2)
    expect(AppointmentNotificationService).to receive(:send_after_missed_visit).with(appointments: common_org.appointments)

    described_class.perform_now
  end
end
