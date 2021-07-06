class CreateReportingMatviewsWithConventionalNames < ActiveRecord::Migration[5.2]
  def change
    execute "SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'"

    create_view :reporting_monthly_patient_blood_pressures, materialized: true
    create_view :reporting_monthly_patient_visits, materialized: true
    create_view :reporting_monthly_patient_states, materialized: true

    drop_view :reporting_patient_states_per_month, revert_to_version: 2
    drop_view :reporting_patient_visits_per_month, revert_to_version: 2
    drop_view :reporting_patient_blood_pressures_per_month, revert_to_version: 1
  end
end
