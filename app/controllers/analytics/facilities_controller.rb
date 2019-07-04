class Analytics::FacilitiesController < AnalyticsController
  before_action :set_facility

  def show
    facility_analytics = @facility.dashboard_analytics
    available_users = policy_scope(User).where(id: facility_analytics.keys)

    @analytics = facility_analytics.map do |user_id, data|
      user = available_users.detect { |f| f.id == user_id }
      [user, data]
    end.to_h
  end

  def share_anonymized_data
    recipient_email = current_admin.email
    recipient_name = recipient_email.split('@').first

    AnonymizedDataDownloadJob.perform_later(recipient_name,
                                            recipient_email,
                                            { facility_id: @facility.id },
                                            'facility')

    redirect_to analytics_facility_path(id: @facility.id),
                notice: I18n.t('anonymized_data_download_email.facility_notice', facility_name: @facility.name)
  end

  private

  def set_facility
    facility_id = params[:id] || params[:facility_id]
    @facility = Facility.friendly.find(facility_id)
    authorize(@facility)
  end
end

