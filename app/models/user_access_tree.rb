#
# Even with Rails caching most of the access-related queries,
# the sheer volume of the number of queries can really slow down page rendering
#
# This class tries to provide an easy and fast way (mostly constant time) to lookup the visible access tree of a user
class UserAccessTree < Struct.new(:user)
  include Memery

  def facilities
    visible_facilities.map { |facility|
      info = {
        visible: true
      }

      [facility, info]
    }.to_h
  end

  def facility_groups
    facilities
      .group_by { |facility, _| facility.facility_group }
      .map { |facility_group, facilities|
      info = {
        accessible_facility_count: facilities.length,
        visible: visible_facility_groups.include?(facility_group),
        facilities: facilities
      }

      [facility_group, info]
    }.to_h
  end

  def organizations
    facility_groups
      .group_by { |facility_group, _| facility_group.organization }
      .map { |organization, facility_groups|
      info = {
        accessible_facility_count: facility_groups.sum { |_, info| info[:accessible_facility_count] },
        visible: visible_organizations.include?(organization),
        facility_groups: facility_groups
      }

      [organization, info]
    }.to_h
  end

  private

  memoize def visible_facility_groups
    user.accessible_facility_groups(:view)
  end

  memoize def visible_facilities
    user.accessible_facilities(:view)
  end

  memoize def visible_organizations
    user.accessible_organizations(:view)
  end
end
