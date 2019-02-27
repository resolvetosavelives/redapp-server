module FacilityFiltering
  extend ActiveSupport::Concern

  included do
    before_action :set_facility_id, only: [:index]

    private

    def set_facility_id
      @facility_id = params[:facility_id].present? ? params[:facility_id] : 'All'
    end

    def selected_facilities
      if @facility_id == 'All'
        policy_scope(Facility.all)
      else
        policy_scope(Facility.where(id: @facility_id))
      end
    end
  end
end
