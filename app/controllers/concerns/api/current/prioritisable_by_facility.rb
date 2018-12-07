module Api::Current::PrioritisableByFacility
  extend ActiveSupport::Concern
  included do
    def current_facility_records
      facility_group_records
        .where(facility: current_facility)
        .updated_on_server_since(current_facility_processed_since, limit)
    end

    def other_facility_records
      other_facilities_limit = limit - current_facility_records.count
      facility_group_records
        .where.not(facility: current_facility.id)
        .updated_on_server_since(other_facilities_processed_since, other_facilities_limit)
    end
  end
end
