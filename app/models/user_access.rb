class UserAccess < Struct.new(:user)
  class NotAuthorizedError < StandardError; end
  class AuthorizationNotPerformedError < StandardError; end

  LEVELS = {
    call_center: {
      id: :call_center,
      name: "Manage: Overdue List",
      grant_access: [],
      description: "Can view and update overdue lists"
    },

    viewer_reports_only: {
      id: :viewer_reports_only,
      name: "View: Aggregate Reports",
      grant_access: [],
      description: "Can view reports"
    },

    viewer_all: {
      id: :viewer_all,
      name: "View: Everything",
      grant_access: [],
      description: "Can view everything"
    },

    manager: {
      id: :manager,
      name: "Manager",
      grant_access: [:call_center, :viewer_reports_only, :viewer_all, :manager],
      description: "Can manage stuff"
    },

    power_user: {
      id: :power_user,
      name: "Power User",
      description: "Can manage everything"
    }
  }.freeze

  ACTION_TO_LEVEL = {
    manage_overdue_list: [:manager, :viewer_all, :call_center],
    view_reports: [:manager, :viewer_all, :viewer_reports_only],
    view_pii: [:manager, :viewer_all],
    manage: [:manager]
  }.freeze

  def accessible_organizations(action)
    resources_for(Organization, action)
  end

  def accessible_facility_groups(action)
    resources_for(FacilityGroup, action)
      .or(FacilityGroup.where(organization: accessible_organizations(action)))
  end

  def accessible_facilities(action)
    resources_for(Facility, action)
      .or(Facility.where(facility_group: accessible_facility_groups(action)))
  end

  def can?(action, model, record = nil)
    if record&.is_a? ActiveRecord::Relation
      raise ArgumentError, "record should not be an ActiveRecord::Relation."
    end

    case model
      when :facility
        can_access_record?(accessible_facilities(action), record)
      when :organization
        can_access_record?(accessible_organizations(action), record)
      when :facility_group
        can_access_record?(accessible_facility_groups(action), record)
      else
        raise ArgumentError, "Access to #{model} is unsupported."
    end
  end

  def authorize(action, model, record = nil)
    RequestStore.store[:access_authorized] = true

    raise AuthorizationNotPerformedError, self.class unless can?(action, model, record)
  end

  private

  def can_access_record?(resources, record)
    return true if user.power_user?
    return resources.find_by_id(record).present? if record
    resources.exists?
  end

  def resources_for(resource_model, action)
    return resource_model.all if user.power_user?
    return resource_model.none unless ACTION_TO_LEVEL.fetch(action).include?(user.access_level.to_sym)

    resource_ids =
      user
        .accesses
        .where(resource_type: resource_model.to_s)
        .map(&:resource_id)

    resource_model.where(id: resource_ids)
  end
end
