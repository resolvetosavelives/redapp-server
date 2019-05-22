class Analytics::FacilitiesController < AnalyticsController
  before_action :set_facility
  before_action :set_organization
  before_action :set_organization_district

  def show
    @facility_analytics = @facility.patient_set_analytics(@from_time, @to_time)
    @user_analytics = user_analytics
  end

  private

  def set_facility
    facility_id = params[:id] || params[:facility_id]
    @facility = Facility.friendly.find(facility_id)
    authorize(@facility)
  end

  def set_organization_district
    @organization_district = OrganizationDistrict.new(@facility.district, @organization)
  end

  def set_organization
    @organization = @facility.organization
  end

  def set_cache_key
    @cache_key = ["view", @facility.analytics_cache_key(@from_time, @to_time)]
  end

  def users_for_facility
    User.joins(:blood_pressures).where('blood_pressures.facility_id = ?', @facility.id).order(:full_name).distinct
  end

  def user_analytics
    users_for_facility.map { |user| [user, Analytics::UserAnalytics.new(user, @facility)] }.to_h
  end
end

