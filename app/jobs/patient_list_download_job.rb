class PatientListDownloadJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(recipient_email, model_type, params, with_medication_history: false)
    case model_type
    when "facility"
      model = Facility.find(params[:facility_id])
      model_name = model.name
    when "facility_group"
      model = FacilityGroup.find(params[:id])
      model_name = model.name
    else
      raise ArgumentError, "unknown model_type #{model_type.inspect}"
    end

    exporter = with_medication_history ? PatientsWithHistoryExporter : PatientsExporter
    patients_csv = exporter.csv(model.assigned_patients)

    PatientListDownloadMailer.patient_list(recipient_email, model_type, model_name, patients_csv).deliver_later
  end
end
