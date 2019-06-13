class Analytics::DistrictsController < AnalyticsController
  before_action :set_organization
  before_action :set_district
  before_action :set_facilities

  def show
    @days_previous = 20
    @months_previous = 8

    @district_analytics = district_analytics(@from_time, @to_time)
    @facility_analytics = facility_analytics(@from_time, @to_time)
  end

  def share_anonymized_data
    recipient_role = current_admin.role
    recipient_email = current_admin.email
    recipient_name = recipient_email.split('@').first

    AnonymizedDataDownloadJob.perform_later(recipient_name, recipient_email, recipient_role)
  end

  private

  def set_organization
    @organization = Organization.find_by(id: params[:organization_id])
  end

  def set_district
    district_name = params[:id] || params[:district_id]
    @organization_district = OrganizationDistrict.new(district_name, @organization)
    authorize(@organization_district)
  end

  def set_facilities
    @facilities = policy_scope(@organization_district.facilities).order(:name)
  end

  def district_analytics(from_time, to_time)
    @organization_district.patient_set_analytics(from_time, to_time)
  end

  def facility_analytics(from_time, to_time)
    @facilities
      .map { |facility| [facility, facility.patient_set_analytics(from_time, to_time)] }
      .to_h
  end
end
