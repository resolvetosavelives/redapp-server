class AppointmentsController < AdminController
  include FacilityFiltering
  include Pagination

  before_action :set_appointment, only: [:update]

  DEFAULT_SEARCH_FILTERS = ["only_less_than_year_overdue"]

  def index
    authorize { current_admin.accessible_facilities(:manage_overdue_list).any? }

    @search_filters = index_params[:search_filters] || []
    # only apply default search filters on navigating to this page
    # after initial page load, params will at least include a facility
    if index_params.keys.empty?
      @search_filters = DEFAULT_SEARCH_FILTERS
    end

    respond_to do |format|
      format.html do
        @patient_summaries = paginate(patient_summaries(include_excluded: false)).includes(:next_appointment, patient: :appointments)
        render layout: "overdue"
      end
      format.csv do
        @patient_summaries = patient_summaries(include_excluded: true)
        send_data render_to_string("index.csv.erb"), filename: download_filename
      end
    end
  end

  def update
    call_result = appointment_params[:call_result].to_sym
    search_filters = appointment_params[:search_filters]&.split || []

    if set_appointment_status_from_call_result(@appointment, call_result)
      appt_params = {facility_id: selected_facility_id, page: page, search_filters: search_filters}
      notice = %(Saved. #{@appointment.patient.full_name} marked as "#{call_result.to_s.humanize}")
      redirect_to appointments_url(params: appt_params), notice: notice
    else
      redirect_back fallback_location: root_path, alert: "Something went wrong!"
    end
  end

  private

  def index_params
    @index_params ||= params.permit(:facility_id, :per_page, search_filters: [])
  end

  def set_appointment
    @appointment = Appointment.find(params[:id] || params[:appointment_id])
    authorize { current_admin.accessible_facilities(:manage_overdue_list).include?(@appointment.facility) }
  end

  def appointment_params
    params.require(:appointment).permit(:call_result, :search_filters)
  end

  def set_appointment_status_from_call_result(appointment, call_result)
    if call_result == :agreed_to_visit
      appointment.mark_patient_agreed_to_visit
    elsif call_result == :patient_has_already_visited
      appointment.mark_patient_already_visited
    elsif call_result == :remind_to_call_later
      appointment.mark_remind_to_call_later
    elsif Appointment.cancel_reasons.value? call_result.to_s
      appointment.mark_appointment_cancelled(call_result)
    end

    appointment.save
    appointment.update_patient_status
  end

  def selected_facility_id
    params[:appointment][:selected_facility_id]
  end

  def page
    params[:appointment][:page]
  end

  def download_filename
    facility_name = current_facility.present? ? current_facility.name.parameterize : "all"
    "overdue-patients_#{facility_name}_#{Time.current.to_s(:number)}.csv"
  end

  def patient_summaries(include_excluded: false)
    PatientSummaryQuery.call(
      assigned_facility: current_facility,
      next_appointment_facilities: current_admin.accessible_facilities(:manage_overdue_list),
      filters: @search_filters,
      include_excluded: include_excluded
    ).order(risk_level: :desc, next_appointment_scheduled_date: :desc, id: :asc)
  end
end
