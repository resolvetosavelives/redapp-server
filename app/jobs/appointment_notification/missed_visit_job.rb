class AppointmentNotification::MissedVisitJob < ApplicationJob
  queue_as :high

  def perform
    unless Flipper.enabled?(:appointment_reminders)
      logger.info class: self.class.name, msg: "appointment_reminders feature is disabled"
      return
    end

    Organization.all.each do |organization|
      AppointmentNotificationService.send_after_missed_visit(appointments: organization.appointments)
    end
  end
end
