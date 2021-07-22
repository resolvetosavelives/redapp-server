class AddReportingFacilityStates < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_facility_states, version: 1, materialized: true
    add_index :reporting_facility_states, [:month_date, :facility_region_id], name: :facility_states_month_date_region_id, unique: true
  end
end
