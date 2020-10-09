class MigratePermissionsToAccesses < ActiveRecord::Migration[5.2]
  require "tasks/scripts/create_accesses_from_permissions"

  def up
    # This is a dev-env only migration
    unless Rails.env.development?
      return
    end

    Organization.all.each do |organization|
      CreateAccessesFromPermissions.do(organization: organization, dryrun: false)
    end

    # Promoting admins with custom permissions or missing accesses to power_users
    custom_admins = User.admins.select { |admin| (!admin.power_user? && admin.accesses.empty?) }

    custom_admins.each do |custom_admin|
      custom_admin.update(access_level: :power_user)
      custom_admin.save
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
