# frozen_string_literal: true

# Creates the specified permission for users who have the specified access_level
class AddPermissionToAccessLevel
  attr_reader :permission_name, :access_level_name, :access_level, :permission, :users

  def initialize(permission_name, access_level_name)
    @permission_name = permission_name
    @access_level_name = access_level_name
    @permission = Permissions::ALL_PERMISSIONS[permission_name]
    @access_level = Permissions::ACCESS_LEVELS.find { |level| level[:name] == access_level_name }
    @users = eligible_users
  end

  def valid?
    return true if permission && valid_permission_for_access_level?

    false
  end

  def create
    return false unless valid?

    users.map do |user|
      permission_resources(user).map do |resource|
        Rails.logger.info log_message(permission: permission, user: user, resource: resource)
        UserPermission.find_or_create_by!(user: user,
                                          permission_slug: permission[:slug],
                                          resource_type: resource[:resource_type],
                                          resource_id: resource[:resource_id])
      end
    end
  end

  private

  def eligible_users
    User.includes(:user_permissions).where.not(user_permissions: {id: nil})
      .select(&method(:eligible?))
  end

  def permission_resources(user)
    return [{resource_type: nil, resource_id: nil}] if permission[:resource_priority] == [:global]

    case permission_resource_type(user.user_permissions.map(&:resource_type).uniq)
    when :facility_group
      user.user_permissions.where(resource_type: "FacilityGroup").map(&method(:permission_resource)).uniq
    when :organization
      user.user_permissions.where(resource_type: "Organization").map(&method(:permission_resource)).uniq
    when :global
      [{resource_type: nil, resource_id: nil}]
    else
      []
    end
  end

  def permission_resource(resource)
    resource.slice(:resource_type, :resource_id)
  end

  def permission_resource_type(user_resource_types)
    return :facility_group if permission[:resource_priority].include?(:facility_group) &&
      user_resource_types.include?("FacilityGroup")

    return :organization if permission[:resource_priority].include?(:organization) &&
      user_resource_types.include?("Organization")

    :global if permission[:resource_priority].include?(:global) &&
      user_resource_types.include?(nil)
  end

  def eligible?(user)
    user_permissions = user.user_permissions.map(&:permission_slug).uniq.sort.map(&:to_sym)
    required_permissions = permission[:required_permissions]
    access_level_permissions = access_level[:default_permissions].uniq.sort

    user_permissions == access_level_permissions - [permission_name] &&
      (user_permissions & required_permissions) == required_permissions
  end

  def valid_permission_for_access_level?
    access_level && access_level[:default_permissions].include?(permission_name)
  end

  def log_message(permission:, user:, resource:)
    return "Creating a global '#{permission[:slug]}' permission for User: #{user.full_name} (#{user.id})" if
      resource[:resource_type].nil?

    "Creating a '#{permission[:slug]}' permission for User: #{user.full_name} (#{user.id}), "\
    "with Resource type: '#{resource[:resource_type]}' and Resource id: #{resource[:resource_id]}"
  end
end
