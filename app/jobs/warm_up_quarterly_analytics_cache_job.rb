class WarmUpQuarterlyAnalyticsCacheJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform
    perform_caching_for_facility_group(n)
    perform_caching_for_districts(n)
  end

  private

  def perform_caching_for_facility_group(n)
    (1..4).each do |n|
      range = ApplicationController.helpers.range_for_quarter(-1 * n)
      FacilityGroup.all.each do |facility_group|
        WarmUpFacilityGroupAnalyticsCacheJob.perform_later(
          facility_group,
          range[:from_time].strftime('%Y-%m-%d'),
          range[:to_time].strftime('%Y-%m-%d'))
      end
    end
  end

  def perform_caching_for_districts(n)
    (1..4).each do |n|
      range = ApplicationController.helpers.range_for_quarter(-1 * n)

      organizations = Organization.all

      organizations.each do |organization|
        district_facilities_map = organization.facility_groups.flat_map(&:facilities).group_by(&:district)

        district_facilities_map.each do |id, facilities|
          district = District.new(id)
          district.organization_id = organization.id
          district.facilities = facilities

          WarmUpDistrictAnalyticsCacheJob.perform_later(
            district,
            range[:from_time].strftime('%Y-%m-%d'),
            range[:to_time].strftime('%Y-%m-%d'))
        end
      end
    end
  end
end

