module Seed
  class ExperimentSeeder
    include ActiveSupport::Benchmarkable

    def self.call(experiment_name: "test-experiment", experiment_type: "current_patients")
      experiment = Experimentation::Experiment.create!(name: experiment_name, experiment_type: "current_patients", state: "new")

      _control_group = experiment.treatment_groups.create!(description: "control")

      single_group = experiment.treatment_groups.create!(description: "emotional_guilt")
      single_group.reminder_templates.create!(message: "notifications.set01.emotional_guilt", remind_on_in_days: -1)

      cascade = experiment.treatment_groups.create!(description: "professional_request")
      cascade.reminder_templates.create!(message: "notifications.set01.professional_request", remind_on_in_days: -1)
      cascade.reminder_templates.create!(message: "notifications.set02.professional_request", remind_on_in_days: 0)
      cascade.reminder_templates.create!(message: "notifications.set03.professional_request", remind_on_in_days: 1)
    end
  end
end
