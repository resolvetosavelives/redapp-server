module Reports
  class FacilityState < Matview
    self.table_name = "reporting_facility_states"

    def self.for_facility(region_or_facility)
      where(facility_region_id: region_or_facility.region.id)
    end
  end
end
