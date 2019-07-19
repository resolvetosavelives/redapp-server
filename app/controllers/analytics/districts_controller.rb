class Analytics::DistrictsController < AnalyticsController
  before_action :set_organization_district

  def show
    district_analytics = @organization_district.dashboard_analytics
    available_facilities = policy_scope(Facility).where(id: district_analytics.keys)

    @analytics =
      available_facilities.inject({}) do |acc, facility|
        acc[facility] = district_analytics[facility.id]
        acc
      end
  end

  def share_anonymized_data
    recipient_email = current_admin.email
    recipient_name = recipient_email.split('@').first

    AnonymizedDataDownloadJob.perform_later(recipient_name,
                                            recipient_email,
                                            { district_name: @organization_district.district_name,
                                              organization_id: @organization_district.organization.id },
                                            'district')

    redirect_to analytics_organization_district_path(id: @organization_district.district_name),
                notice: I18n.t('anonymized_data_download_email.district_notice',
                               district_name: @organization_district.district_name)
  end

  private

  def set_organization_district
    district_name = params[:id] || params[:district_id]
    organization = Organization.find_by(id: params[:organization_id])
    @organization_district = OrganizationDistrict.new(district_name, organization)
    authorize(@organization_district)
  end
end
