class ApprovalNotifierMailer < ApplicationMailer
  attr_reader :user

  def registration_approval_email(user_id:)
    @user = User.find(user_id)
    subject = I18n.t("registration_approval_email.subject",
      full_name: @user.full_name,
      org_name: @user.facility_group.organization.name)
    mail(subject: subject,
         to: supervisor_emails,
         cc: organization_owner_emails,
         bcc: owner_emails)
  end

  def reset_password_approval_email(user_id:)
    @user = User.find(user_id)
    subject = I18n.t("reset_password_approval_email.subject", full_name: @user.full_name)
    mail(subject: subject,
         to: supervisor_emails,
         cc: organization_owner_emails,
         bcc: owner_emails)
  end

  private

  def supervisor_emails
    users = UserPermission.where(permission_slug: :approve_health_workers, resource: user.facility_group).map(&:user)
    users.map(&:email).join(",")
  end

  def organization_owner_emails
    users = UserPermission.where(permission_slug: :approve_health_workers, resource: user.organization).map(&:user)
    users.map(&:email).join(",")
  end

  def owner_emails
    users = UserPermission.where(permission_slug: :approve_health_workers, resource: nil).map(&:user)
    users.map(&:email).join(",")
  end
end
