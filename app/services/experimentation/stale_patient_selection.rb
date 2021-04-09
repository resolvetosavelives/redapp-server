module Experimentation
  class StalePatientSelection
    def self.call(*args)
      new(*args).call
    end

    attr_reader :eligible_range
    attr_reader :start_date

    def initialize(start_date:, eligible_range:)
      @eligible_range = eligible_range
      @start_date = start_date
    end

    def call
      patient_pool.joins(:encounters)
        .where(encounters: {device_created_at: eligible_range})
        .where("NOT EXISTS (SELECT 1 FROM encounters WHERE encounters.patient_id = patients.id AND
              encounters.device_created_at > ?)", eligible_range.end)
        .left_joins(:appointments)
        .where("NOT EXISTS (SELECT 1 FROM appointments WHERE appointments.patient_id = patients.id AND
              appointments.scheduled_date >= ?)", start_date)
        .distinct
        .pluck(:id)
    end

    def patient_pool
      Patient.from(Patient.with_hypertension, :patients)
        .contactable
        .where("age >= ?", 18)
        .includes(treatment_group_memberships: [treatment_group: [:experiment]])
        .where(["experiments.end_date < ? OR experiments.id IS NULL", ExperimentControlService::LAST_EXPERIMENT_BUFFER.ago]).references(:experiment)
    end
  end
end
