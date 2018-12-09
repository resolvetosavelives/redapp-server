class ApprovalNotifierMailer < ApplicationMailer
  attr_reader :user

  default :from => 'help@simple.org'

  def admin_emails(role)
    user.facility_group.admins.where(role: role).pluck(:email)
  end

  def supervisor_emails
    admin_emails('supervisor').join(',')
  end

  def owner_emails
    admin_emails('owner').join(',')
  end

  def registration_approval_email
    @user = params[:user]
    subject = I18n.t('registration_approval_email.subject', full_name: @user.full_name)
    mail(subject: subject,
         to: supervisor_emails,
         cc: owner_emails)
  end

  def reset_password_approval_email
    @user = params[:user]
    subject = I18n.t('reset_password_approval_email.subject', full_name: @user.full_name)
    mail(subject: subject,
         to: supervisor_emails,
         cc: owner_emails)
  end
end
