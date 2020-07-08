class AppointmentNotificationService
  def self.send_after_missed_visit(*args)
    new(*args).send_after_missed_visit
  end

  def initialize(appointments:, days_overdue: 3, schedule_at:)
    @appointments = appointments
    @days_overdue = days_overdue
    @schedule_at = schedule_at

    @communication_type = if FeatureToggle.enabled?("WHATSAPP_APPOINTMENT_REMINDERS")
      Communication.communication_types[:missed_visit_whatsapp_reminder]
    else
      Communication.communication_types[:missed_visit_sms_reminder]
    end
  end

  def send_after_missed_visit
    eligible_appointments = appointments.eligible_for_reminders(days_overdue: days_overdue)

    eligible_appointments.each do |appointment|
      next if appointment.previously_communicated_via?(communication_type)

      AppointmentNotification::Worker.perform_at(schedule_at, appointment.id, communication_type)
    end
  end

  private

  attr_reader :appointments, :communication_type, :days_overdue, :schedule_at
end
