class UserAccess
  class NotAuthorizedError < StandardError; end

  class AuthorizationNotPerformedError < StandardError; end

  attr_reader :user
  def initialize(user)
    @user = user
  end

  LEVELS = {
    manager: {
      id: :manager,
      name: "Manager",
      grant_access: [:call_center, :viewer_reports_only, :viewer_all, :manager],
      description: "Can manage regions, facilities, admins, users, and view everything"
    },

    viewer_reports_only: {
      id: :viewer_reports_only,
      name: "View: Reports only",
      grant_access: [],
      description: "Can only view reports"
    },

    viewer_all: {
      id: :viewer_all,
      name: "View: Everything",
      grant_access: [],
      description: "Can view patient data and all facility data"
    },

    call_center: {
      id: :call_center,
      name: "Call center staff",
      grant_access: [],
      description: "Can only manage overdue patients list"
    },

    power_user: {
      id: :power_user,
      name: "Power User",
      description: "Power user: Can manage the entire Simple deployment"
    }
  }.freeze

  ANY_ACTION = :any
  ACTION_TO_LEVEL = {
    manage_overdue_list: [:manager, :viewer_all, :call_center],
    view_reports: [:manager, :viewer_all, :viewer_reports_only],
    view_pii: [:manager, :viewer_all],
    manage: [:manager]
  }.freeze

  def accessible_organizations(action)
    resources_for(Organization, action)
      .includes(facility_groups: :facilities)
  end

  def accessible_facility_groups(action)
    resources_for(FacilityGroup, action)
      .union(FacilityGroup.where(organization: accessible_organizations(action)))
      .includes(:organization)
      .includes(:facilities)
  end

  def accessible_blocks(action)
    district_regions = accessible_facility_groups(action).includes(:region).map(&:region)
    paths = district_regions.pluck(:path)
    globs = paths.map { |path| " '#{path}.*' "}.join(",")
    Region.block_regions.where("path ? ARRAY[#{globs}]::lquery[]")
  end

  def accessible_facilities(action)
    resources_for(Facility, action)
      .union(Facility.where(facility_group: accessible_facility_groups(action)))
      .includes(facility_group: :organization)
  end

  def accessible_admins(action)
    return User.none unless action == :manage
    return User.admins if power_user?
    return User.none unless action_to_level(:manage).include?(user.access_level.to_sym)

    manageable_facilities = user.accessible_facilities(:manage)
    manageable_facility_groups = user.accessible_facility_groups(:manage)
    manageable_orgs = user.accessible_organizations(:manage)

    resource_ids =
      [
        manageable_facilities.pluck("facilities.id"),
        manageable_facilities.map(&:facility_group_id),
        manageable_facilities.map(&:organization_id),
        manageable_facility_groups.map(&:id),
        manageable_facility_groups.map(&:organization_id),
        manageable_orgs.map(&:id)
      ].flatten.uniq

    User
      .admins
      .from(User
              .admins
              .select("DISTINCT ON (users.id) users.*")
              .joins(:accesses)
              .where(accesses: {resource_id: resource_ids}), "users")
  end

  def accessible_users(action)
    return User.none unless [:manage, :view_reports, :view_pii].include?(action)
    return User.non_admins if power_user?
    return User.none unless action_to_level(action).include?(user.access_level.to_sym)

    User
      .non_admins
      .where(phone_number_authentications: {registration_facility_id: accessible_facilities(action)})
  end

  def accessible_protocols(action)
    return Protocol.all if action == :manage && power_user?
    return Protocol.all if action == :manage && accessible_organizations(:manage).any?

    Protocol.none
  end

  def accessible_protocol_drugs(action)
    return ProtocolDrug.all if action == :manage && power_user?
    return ProtocolDrug.all if action == :manage && accessible_organizations(:manage).any?

    ProtocolDrug.none
  end

  def access_across_organizations?(action)
    accessible_facilities(action).group_by(&:organization).keys.length > 1
  end

  def access_across_facility_groups?(action)
    accessible_facilities(action).group_by(&:facility_group).keys.length > 1
  end

  def permitted_access_levels
    return LEVELS.keys if power_user?

    LEVELS[user.access_level.to_sym][:grant_access]
  end

  def manage_organization?
    power_user? || user.accessible_organizations(:manage).any?
  end

  def grant_access(new_user, selected_facility_ids)
    raise NotAuthorizedError unless permitted_access_levels.include?(new_user.access_level.to_sym)
    return if new_user.power_user?
    return if selected_facility_ids.blank?

    resources = prepare_grantable_resources(selected_facility_ids)
    # if the user couldn't prepare resources for new_user means they shouldn't have had access to this operation at all
    raise NotAuthorizedError if resources.empty?

    # recreate accesses from scratch to handle deletes/edits/updates seamlessly
    User.transaction do
      new_user.accesses.delete_all
      new_user.accesses.create!(resources)
    end
  end

  private

  def resources_for(resource_model, action)
    return resource_model.all if power_user?
    return resource_model.none unless action_to_level(action).include?(user.access_level.to_sym)

    resource_ids =
      user
        .accesses
        .where(resource_type: resource_model.to_s)
        .map(&:resource_id)

    resource_model.where(id: resource_ids)
  end

  #
  # Compare the new user's selected facilities with the currently accessible facilities of the current user
  # and see if we can promote the new user's access if necessary
  def prepare_grantable_resources(selected_facility_ids)
    selected_facilities = Facility.where(id: selected_facility_ids).includes(facility_group: :organization)
    resources = []

    # TODO: if selected_facility_ids is not a subset of accessible_facilities, then raise NotAuthorizedError

    accessible_facilities_in_org = accessible_facilities(:manage).group_by(&:organization)
    selected_facilities.group_by(&:organization).each do |org, selected_facilities_in_org|
      if accessible_organizations(:manage).find_by_id(org).present? &&
          (accessible_facilities_in_org[org].to_set == selected_facilities_in_org.to_set)

        resources << {resource_type: Organization.name, resource_id: org.id}
        selected_facilities -= selected_facilities_in_org
      end
    end

    accessible_facilities_in_fg = accessible_facilities(:manage).group_by(&:facility_group)
    selected_facilities.group_by(&:facility_group).each do |fg, selected_facilities_in_fg|
      if accessible_facility_groups(:manage).find_by_id(fg).present? &&
          (accessible_facilities_in_fg[fg].to_set == selected_facilities_in_fg.to_set)

        resources << {resource_type: FacilityGroup.name, resource_id: fg.id}
        selected_facilities -= selected_facilities_in_fg
      end
    end

    selected_facilities.each do |f|
      if accessible_facilities(:manage).find_by_id(f).present?
        resources << {resource_type: Facility.name, resource_id: f.id}
      end
    end

    resources.flatten
  end

  def power_user?
    user.power_user?
  end

  def action_to_level(action)
    return ACTION_TO_LEVEL.values.flatten.uniq if action == ANY_ACTION
    ACTION_TO_LEVEL[action]
  end
end
