module ReportingPipeline
  class MonthlyPatientVisit < Matview
    self.table_name = "reporting_monthly_patient_visits"
    belongs_to :patient
  end
end
