class PatientsController < CounsellorController
  before_action :set_patient, only: [:update]

  def index
    authorize Patient, :index?

    patients_to_show = policy_scope(Patient)
                         .not_contacted
                         .where(registration_facility: selected_facilities)

    @patients = patients_to_show
                  .order(device_created_at: :asc)
                  .page(params[:page])
                  .per(per_page_count(patients_to_show))
  end

  def update
    if @patient.update(patient_params)
      redirect_to patients_url, notice: "Saved. #{@patient.full_name} marked as \"#{@patient.call_result.humanize}\""
    else
      redirect_back fallback_location: root_path, alert: 'Something went wrong!'
    end
  end

  private

  def set_patient
    @patient = Patient.find(params[:id] || params[:patient_id])
    authorize @patient
  end

  def patient_params
    params.require(:patient).permit(:call_result)
  end
end
