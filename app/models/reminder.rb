class Reminder < ApplicationRecord
  belongs_to :patient
  belongs_to :appointment, optional: true
  belongs_to :experiment, class_name: "Experimentation::Experiment", optional: true
  belongs_to :reminder_template, class_name: "Experimentation::ReminderTemplate", optional: true

  validates :status, presence: true
  validates :remind_on, presence: true
  validates :message, presence: true

  enum status: {
    pending: "pending",
    sent: "sent",
    cancelled: "cancelled"
  }, _prefix: true
end
