class Admin::UsersController < AdminController
  include Pagination
  include SearchHelper

  before_action :set_user, except: [:index, :teleconsult_search]
  around_action :set_reporting_time_zone, only: [:show]
  before_action :set_district, only: [:index]

  def index
    authorize { current_admin.accessible_users(:manage).any? }

    facilities = if @district == "All"
      current_admin.accessible_facilities(:manage)
    else
      current_admin.accessible_facilities(:manage).where(district: @district)
    end

    users = current_admin.accessible_users(:manage)
      .joins(phone_number_authentications: :facility)
      .where(phone_number_authentications: {registration_facility_id: facilities})
      .order("users.full_name", "facilities.name", "users.device_created_at")

    @users =
      if searching?
        paginate(users.search_by_name_or_phone(search_query))
      else
        paginate(users)
      end
  end

  def teleconsult_search
    authorize { current_admin.accessible_users(:manage).any? }

    facility_group = FacilityGroup.find(params[:facility_group_id])
    facilities = current_admin.accessible_facilities(:manage).where(facility_group: facility_group)

    users = current_admin.accessible_users(:manage)
      .joins(phone_number_authentications: :facility)
      .where(phone_number_authentications: {registration_facility_id: facilities})
      .order("users.full_name", "facilities.name", "users.device_created_at")

    respond_to do |format|
      format.json { @users = users.teleconsult_search(search_query) }
    end
  end

  def show
    @recent_blood_pressures = paginate(
      recent_bp_log(@user.blood_pressures).includes(:patient, :facility)
    )
  end

  def edit
    @user.teleconsultation_isd_code ||= Rails.application.config.country["sms_country_code"]
  end

  def update
    if @user.update_with_phone_number_authentication(user_params)
      redirect_to admin_user_url(@user), notice: "User was successfully updated."
    else
      render :edit
    end
  end

  def reset_otp
    phone_number_authentication = @user.phone_number_authentication
    phone_number_authentication.set_otp
    phone_number_authentication.save

    RequestOtpSmsJob.perform_later(@user)
    redirect_to admin_user_url(@user), notice: "User OTP has been reset."
  end

  def disable_access
    reason_for_denial =
      I18n.t("admin.denied_access_to_user", admin_name: current_admin.email.split("@").first) + "; " +
      params[:reason_for_denial].to_s

    @user.sync_approval_denied(reason_for_denial)
    @user.save
    redirect_to request.referer || admin_user_url(@user), notice: "User access has been disabled."
  end

  def enable_access
    @user.sync_approval_allowed(
      I18n.t("admin.allowed_access_to_user", admin_name: current_admin.email.split("@").first)
    )
    @user.save
    redirect_to request.referer || admin_user_url(@user), notice: "User access has been enabled."
  end

  private

  def ordered_sync_approval_statuses
    {requested: 0, denied: 1, allowed: 2}.with_indifferent_access
  end

  def set_user
    @user = authorize { current_admin.accessible_users(:manage).find(params[:id] || params[:user_id]) }
  end

  def user_params
    params.require(:user).permit(
      :full_name,
      :phone_number,
      :teleconsultation_phone_number,
      :teleconsultation_isd_code,
      :password,
      :password_confirmation,
      :sync_approval_status,
      :registration_facility_id
    )
  end

  def set_district
    @district = params[:district].present? ? params[:district] : "All"
  end
end
