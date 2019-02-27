class Analytics::FacilitiesController < AnalyticsController
  def show
    skip_authorization
    @facility = Facility.friendly.find(params[:id])
    @facility_group = @facility.facility_group
    @organization = @facility_group.organization

    @facility_analytics = Analytics::FacilityAnalytics.new(@facility, from_time: 90.days.ago, to_time: Date.today).fetch_from_cache
    @user_analytics = users_for_facility.map { |user| [user, Analytics::UserAnalytics.new(user, @facility)] }.to_h
  end

  def graphics
    skip_authorization

    @facility = Facility.friendly.find(params[:facility_id])
    @facility_group = @facility.facility_group
    @organization = @facility_group.organization

    @current_month = Date.today.at_beginning_of_month.to_date
    @from_time = @current_month
    @to_time = @current_month.at_end_of_month

    @facility_analytics = Analytics::FacilityAnalytics.new(
      @facility,
      from_time: @from_time, to_time: @to_time, months_previous: 6)
  end

  private

  def users_for_facility
    User.joins(:blood_pressures).where('blood_pressures.facility_id = ?', @facility.id).distinct
  end
end