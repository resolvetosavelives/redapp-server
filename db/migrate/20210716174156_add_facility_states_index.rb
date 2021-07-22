class AddFacilityStatesIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :reporting_facility_states, [:month_date, :facility_region_id], unique: true, name: "facility_states_month_date_region_id"
  end
end
