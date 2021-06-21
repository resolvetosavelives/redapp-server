class Notification < ApplicationRecord
  belongs_to :subject, optional: true, polymorphic: true
  belongs_to :patient
  belongs_to :experiment, class_name: "Experimentation::Experiment", optional: true
  belongs_to :reminder_template, class_name: "Experimentation::ReminderTemplate", optional: true
  has_many :communications

  # We have 'sms' in our appointment reminder message keys due to legacy reasons, even though
  # they also sometimes point to whatsapp messages
  APPOINTMENT_REMINDER_MSG_PREFIX = "sms.appointment_reminders"

  validates :status, presence: true
  validates :remind_on, presence: true
  validates :message, presence: true
  validates :purpose, presence: true

  enum status: {
    pending: "pending",
    scheduled: "scheduled",
    sent: "sent",
    cancelled: "cancelled"
  }, _prefix: true
  enum purpose: {
    covid_medication_reminder: "covid_medication_reminder",
    experimental_appointment_reminder: "experimental_appointment_reminder",
    missed_visit_appointment_reminder: "missed_visit_appointment_reminder"
  }, _suffix: true

  scope :due_today, -> { where(remind_on: Date.current, status: [:pending]) }

  def localized_message
    case purpose
    when "missed_visit_appointment_reminder", "experimental_appointment_reminder"
      I18n.t(
        message,
        facility_name: subject.facility.name,
        patient_name: patient.full_name,
        appointment_date: subject.scheduled_date,
        locale: subject.facility.locale
      )
    when "covid_medication_reminder"
      I18n.t(
        message,
        facility_name: patient.assigned_facility.name,
        patient_name: patient.full_name,
        locale: patient.assigned_facility.locale
      )
    else
      raise ArgumentError, "no localized_message defined for notification of type #{purpose}"
    end
  end

  def next_communication_type
    # guarding against experiment state to prevent race condition
    return nil if status_cancelled? || experiment&.cancelled_state?
    if preferred_communication_method && !previously_communicated_by?(preferred_communication_method)
      return preferred_communication_method
    end
    return backup_communication_method unless previously_communicated_by?(backup_communication_method)
    nil
  end

  private

  def previously_communicated_by?(method)
    communications.any? { |communication| communication.communication_type == method }
  end

  def preferred_communication_method
    Flipper.enabled?(:whatsapp_appointment_reminders) ? "missed_visit_whatsapp_reminder" : nil
  end

  def backup_communication_method
    "missed_visit_sms_reminder"
  end
end
