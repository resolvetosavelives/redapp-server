module ReportingPipeline
  class MonthlyPatientBloodPressure < Matview
    self.table_name = "reporting_monthly_patient_blood_pressures"
    belongs_to :patient
  end
end
