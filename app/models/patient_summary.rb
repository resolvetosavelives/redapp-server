class PatientSummary < ActiveRecord::Base
  self.primary_key = :id

  belongs_to :patient, foreign_key: :id
  belongs_to :next_appointment, class_name: "Appointment", foreign_key: :next_appointment_id

  scope :overdue, -> { joins(:next_appointment).merge(Appointment.overdue) }
  scope :all_overdue, -> { joins(:next_appointment).merge(Appointment.all_overdue) }
  scope :passed_unvisited, -> { joins(:next_appointment).merge(Appointment.passed_unvisited) }
  scope :last_year_unvisited, -> { joins(:next_appointment).merge(Appointment.last_year_unvisited) }

  def latest_blood_pressure_to_s
    [latest_blood_pressure_systolic, latest_blood_pressure_diastolic].join("/")
  end

  def readonly?
    true
  end
end
