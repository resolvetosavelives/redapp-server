class AddReportingFacilityStates < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_facility_states, version: 1, materialized: true
  end
end
