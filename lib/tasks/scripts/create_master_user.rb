module CreateMasterUser
  def self.from_admin(admin)
    email_authentication = EmailAuthentication.find_by(email: admin.email)
    if email_authentication.present?
      Rails.logger.info "Skipping #{admin.email}; User is already present: #{email_authentication.user.full_name}"
      return
    end

    admin.transaction do
      admin_attributes = admin.attributes.with_indifferent_access

      master_user = create_user_for_admin!(admin)
      email_authentication = EmailAuthentication.new(admin_attributes.except(:id, :role))
      email_authentication.save!(validate: false)
      master_user.user_authentications.create!(authenticatable: email_authentication)
      assign_permissions!(master_user, admin)
    end
  end

  private_class_method

  def self.master_user_id(email)
    UUIDTools::UUID.md5_create(
      UUIDTools::UUID_DNS_NAMESPACE,
      {email: email}.to_s
    ).to_s
  end

  def self.create_user_for_admin!(admin)
    admin_attributes = admin.attributes.with_indifferent_access

    user_attributes =
      admin_attributes
        .slice(:role, :created_at, :updated_at, :deleted_at)
        .merge(id: master_user_id(admin.email),
               full_name: admin.email.split("@").first,
               organization: get_organization(admin),
               sync_approval_status: "denied",
               sync_approval_status_reason: "User is an admin",
               device_created_at: admin.created_at,
               device_updated_at: admin.updated_at)

    User.create!(user_attributes)
  end

  def self.get_organization(admin)
    return nil if admin.owner?
    organizations =
      if admin.organization_owner?
        admin.admin_access_controls.map(&:access_controllable).uniq
      else
        admin.admin_access_controls.map(&:access_controllable).map(&:organization).uniq
      end

    throw "#{admin.email} belongs to more than one organization" if organizations.length != 1
    organizations.first
  end

  # @todo: User should be enough here
  def self.assign_permissions!(user, admin)
    access_level = Permissions::ACCESS_LEVELS.find { |access_level| access_level[:name] == user.role.to_sym }
    user_permissions = access_level[:default_permissions]
    resources = admin.admin_access_controls
    user_permissions.each do |permission_slug|
      permission = Permissions::ALL_PERMISSIONS[permission_slug]

      throw "#{permission_slug} is an unknown permission" unless permission.present?

      if !resources.present? && permission[:resource_priority].include?(:global)
        user.user_permissions.create!(permission_slug: permission_slug)
        next
      end

      resources.map(&:access_controllable).each do |resource|
        resource_type = resource.class.to_s.underscore.to_sym
        if permission[:resource_priority].include?(resource_type)
          user.user_permissions.create!(permission_slug: permission_slug, resource: resource)
        end
      end
    end
  end

  def self.update_admin_access_controls(admin, master_user)
    admin.admin_access_controls.update_all(user_id: master_user.id)
  end
end
