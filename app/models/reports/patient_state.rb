module Reports
  class PatientState < Matview
    self.table_name = "reporting_patient_states"
    belongs_to :patient

    def self.by_assigned_region(region_or_source)
      region = region_or_source.region
      where("assigned_#{region.region_type}_region_id" => region.id)
    end

    def self.by_month_date(month_date)
      where(month_date: month_date)
    end
  end
end
