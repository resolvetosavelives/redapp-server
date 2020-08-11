class OrganizationDistrict < Struct.new(:district_name, :organization)
  include QuarterHelper

  def district_slug(district_name)
    district_name.split(" ").select(&:present?).join("-").downcase
  end

  def facilities
    organization.facilities.where(district: district_name)
  end

  def registered_patients
    Patient.where(registration_facility: facilities)
  end

  def cohort_analytics(period, prev_periods)
    patients =
      Patient
        .joins(:assigned_facility)
        .where(facilities: {id: facilities})
        .with_hypertension

    query = CohortAnalyticsQuery.new(patients)
    query.patient_counts_by_period(period, prev_periods)
  end

  def dashboard_analytics(period: :month, prev_periods: 3, include_current_period: false)
    query = DistrictAnalyticsQuery.new(district_name,
      facilities,
      period,
      prev_periods,
      include_current_period: include_current_period)

    results = [
      query.registered_patients_by_period,
      query.total_registered_patients,
      query.follow_up_patients_by_period
    ].compact

    return {} if results.blank?
    results.inject(&:deep_merge)
  end
end
