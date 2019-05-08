class WarmUpFacilityGroupAnalyticsCacheJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(facility_group, from_time_string, to_time_string)
    puts "Processing Facility Group #{facility_group.name}"
    from_time = from_time_string.to_time
    to_time = to_time_string.to_time
    facility_group.patient_set_analytics(from_time, to_time)
    facility_group.facilities.each do |facility|
      WarmUpFacilityAnalyticsCacheJob.perform_now(
        facility, from_time, to_time)
    end
    puts "Finished processing Facility Group #{facility_group.name}"
  end
end