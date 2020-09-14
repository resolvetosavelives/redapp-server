class Analytics::FacilitiesController < AnalyticsController
  include GraphicsDownload
  include QuarterHelper
  include Pagination

  before_action :set_facility

  def show
    @show_current_period = true

    set_dashboard_analytics(@period, 6)
    set_cohort_analytics(@period, @prev_periods)

    @recent_blood_pressures = paginate(@facility.recent_blood_pressures)

    respond_to do |format|
      format.html
      format.csv do
        send_data render_to_string("show.csv.erb"), filename: download_filename
      end
    end
  end

  def share_anonymized_data
    recipient_email = current_admin.email
    recipient_name = recipient_email.split("@").first

    AnonymizedDataDownloadJob.perform_later(recipient_name,
      recipient_email,
      {facility_id: @facility.id},
      "facility")

    redirect_to analytics_facility_path(id: @facility.id),
      notice: I18n.t("anonymized_data_download_email.facility_notice", facility_name: @facility.name)
  end

  def patient_list
    recipient_email = current_admin.email

    PatientListDownloadJob.perform_later(recipient_email, "facility", facility_id: @facility.id)

    redirect_to(
      analytics_facility_path(@facility),
      notice: I18n.t("patient_list_email.notice", model_type: "facility", model_name: @facility.name)
    )
  end

  def patient_list_with_history
    recipient_email = current_admin.email

    PatientListDownloadJob.perform_later(recipient_email,
      "facility",
      {facility_id: @facility.id},
      with_medication_history: true)

    redirect_to(
      analytics_facility_path(@facility),
      notice: I18n.t("patient_list_email.notice", model_type: "facility", model_name: @facility.name)
    )
  end

  def whatsapp_graphics
    set_cohort_analytics(:quarter, 3)
    set_dashboard_analytics(:quarter, 4)

    whatsapp_graphics_handler(
      @facility.organization.name,
      @facility.name
    )
  end

  private

  def set_facility
    facility_id = params[:id] || params[:facility_id]
    @facility = Facility.friendly.find(facility_id)
    if current_admin.permissions_v2_enabled?
      authorize_v2 { current_admin.accessible_facilities(:view_reports).include?(@facility) }
    else
      authorize([:cohort_report, @facility])
    end
  end

  def set_cohort_analytics(period, prev_periods)
    @cohort_analytics = @facility.cohort_analytics(period, prev_periods)
  end

  def set_dashboard_analytics(period, prev_periods)
    @dashboard_analytics = @facility.dashboard_analytics(period: period,
                                                         prev_periods: prev_periods,
                                                         include_current_period: @show_current_period)
  end

  def download_filename
    period = @period == :quarter ? "quarterly" : "monthly"
    facility = @facility.name
    time = Time.current.to_s(:number)
    "facility-#{period}-cohort-report_#{facility}_#{time}.csv"
  end
end
