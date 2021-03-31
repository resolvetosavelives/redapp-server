require "csv"

class Appointment < ApplicationRecord
  include ApplicationHelper
  include Mergeable
  include Hashable

  belongs_to :patient, optional: true
  belongs_to :user, optional: true
  belongs_to :facility
  belongs_to :creation_facility, class_name: "Facility", optional: true

  has_many :communications

  ANONYMIZED_DATA_FIELDS = %w[id patient_id created_at registration_facility_name user_id scheduled_date
    overdue status agreed_to_visit remind_on]

  enum status: {
    scheduled: "scheduled",
    cancelled: "cancelled",
    visited: "visited"
  }, _prefix: true

  enum cancel_reason: {
    not_responding: "not_responding",
    moved: "moved",
    dead: "dead",
    invalid_phone_number: "invalid_phone_number",
    public_hospital_transfer: "public_hospital_transfer",
    moved_to_private: "moved_to_private",
    other: "other"
  }

  enum appointment_type: {
    manual: "manual",
    automatic: "automatic"
  }, _prefix: true

  validate :cancel_reason_is_present_if_cancelled
  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  scope :for_sync, -> { with_discarded }

  def self.all_overdue
    where(status: "scheduled")
      .where(arel_table[:scheduled_date].lt(Date.current))
      .where(arel_table[:remind_on].eq(nil).or(arel_table[:remind_on].lteq(Date.current)))
  end

  def self.overdue
    all_overdue.where(arel_table[:scheduled_date].gteq(365.days.ago))
  end

  def self.overdue_by(number_of_days)
    overdue.where("scheduled_date <= ?", Date.current - number_of_days.days)
  end

  def self.eligible_for_reminders(days_overdue: 3)
    overdue_by(days_overdue)
      .joins(:patient)
      .merge(Patient.contactable)
  end

  def days_overdue
    [0, (Date.current - scheduled_date).to_i].max
  end

  def follow_up_days
    [0, (scheduled_date - device_created_at.to_date).to_i].max
  end

  def scheduled?
    status.to_sym == :scheduled
  end

  def overdue?
    scheduled? && scheduled_date <= Date.current
  end

  def overdue_for_over_a_year?
    scheduled? && scheduled_date < 365.days.ago
  end

  def overdue_for_under_a_month?
    scheduled? && scheduled_date > 30.days.ago
  end

  def cancel_reason_is_present_if_cancelled
    if status == :cancelled && !cancel_reason.present?
      errors.add(:cancel_reason, "should be present for cancelled appointments")
    end
  end

  def mark_remind_to_call_later
    self.remind_on = 7.days.from_now
  end

  def mark_patient_agreed_to_visit
    self.agreed_to_visit = true
    self.remind_on = 30.days.from_now
  end

  def mark_appointment_cancelled(cancel_reason)
    self.agreed_to_visit = false
    self.remind_on = nil
    self.cancel_reason = cancel_reason
    self.status = :cancelled
  end

  def mark_patient_already_visited
    self.status = :visited
    self.agreed_to_visit = nil
    self.remind_on = nil
  end

  def update_patient_status
    return unless patient

    case cancel_reason
      when "dead"
        patient.update(status: :dead)
      when "moved_to_private"
        patient.update(status: :migrated)
      when "public_hospital_transfer"
        patient.update(status: :migrated)
      else
        patient.update(status: :active)
    end
  end

  def anonymized_data
    {id: hash_uuid(id),
     patient_id: hash_uuid(patient_id),
     created_at: created_at,
     registration_facility_name: facility.name,
     user_id: hash_uuid(patient&.registration_user&.id),
     scheduled_date: scheduled_date,
     overdue: days_overdue > 0 ? "Yes" : "No",
     status: status,
     agreed_to_visit: agreed_to_visit,
     remind_on: remind_on}
  end

  def previously_communicated_via?(communication_type)
    communications.latest_by_type(communication_type)&.attempted?
  end
end
