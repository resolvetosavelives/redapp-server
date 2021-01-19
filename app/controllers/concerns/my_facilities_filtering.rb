# frozen_string_literal: true

module MyFacilitiesFiltering
  extend ActiveSupport::Concern

  included do
    before_action :populate_accessible_facilities
    before_action :populate_facility_groups
    before_action :set_selected_facility_group
    before_action :populate_zones
    before_action :set_selected_zones
    before_action :populate_facility_sizes
    before_action :set_selected_facility_sizes

    def filter_facilities
      filtered_facilities = facilities_by_facility_group(@accessible_facilities)
      filtered_facilities = facilities_by_size(filtered_facilities)
      facilities_by_zone(filtered_facilities)
    end

    private

    def populate_accessible_facilities
      @accessible_facilities = current_admin.accessible_facilities(:view_reports)
    end

    def populate_facility_groups
      @facility_groups = FacilityGroup.where(id: @accessible_facilities.map(&:facility_group_id).uniq).order(:name)
    end

    def populate_facility_sizes
      @facility_sizes = @accessible_facilities.where(zone: @selected_zones).pluck(:facility_size).uniq.compact.sort
    end

    def populate_zones
      @zones = @accessible_facilities.where(facility_group: @selected_facility_group).pluck(:zone).uniq.compact.sort
    end

    def set_selected_facility_group
      @selected_facility_group = params[:facility_group] ? @facility_groups.find_by(slug: params[:facility_group]) : @facility_groups.first
    end

    def set_selected_zones
      @selected_zones = params[:zone].present? ? [params[:zone]] : @zones
    end

    def set_selected_facility_sizes
      @selected_sizes = params[:size].present? ? [params[:size]] : @facility_sizes
    end

    def facilities_by_facility_group(facilities)
      facilities.where(facility_group: @selected_facility_group)
    end

    def facilities_by_size(facilities)
      if (@facility_sizes - @selected_sizes).empty?
        facilities
      else
        facilities.where(facility_size: @selected_sizes)
      end
    end

    def facilities_by_zone(facilities)
      facilities.where(zone: @selected_zones).or(facilities.where(zone: nil))
    end
  end
end
