require "tzinfo"
require File.expand_path("../config/environment", __dir__)

set :output, "/home/deploy/apps/simple-server/shared/log/cron.log"

env :PATH, ENV["PATH"]
DEFAULT_CRON_TIME_ZONE = "Asia/Kolkata"

def local(time)
  TZInfo::Timezone.get(Rails.application.config.country[:time_zone] || DEFAULT_CRON_TIME_ZONE)
    .local_to_utc(Time.parse(time))
end

every :day, at: local("11:00 pm").utc, roles: [:cron] do
  rake "appointment_notification:three_days_after_missed_visit"
end

every :day, at: local("12:00 am"), roles: [:whitelist_phone_numbers] do
  rake "exotel_tasks:whitelist_patient_phone_numbers"
end

every :week, at: local("01:00 am"), roles: [:whitelist_phone_numbers] do
  rake "exotel_tasks:update_all_patients_phone_number_details"
end

every :day, at: local("12:30am"), roles: [:cron] do
  rake "db:refresh_materialized_views"
end

every :day, at: local("01:00 am"), roles: [:cron] do
  runner "MarkPatientMobileNumbers.call"
end

every :day, at: local("02:00 am"), roles: [:cron] do
  runner "PatientDeduplication::Runner.new(PatientDeduplication::Strategies.identifier_and_full_name_match).perform"
end

every :day, at: local("04:00 am"), roles: [:cron] do
  runner "Reports::RegionCacheWarmer.call"
end

every :day, at: local("05:00 am"), roles: [:cron] do
  runner "DuplicatePassportAnalytics.report"
end

every :monday, at: local("6:00 am"), roles: [:cron] do
  if Flipper.enabled?(:weekly_telemed_report)
    rake "reports:telemedicine"
  end
end

every :day, at: local("07:00 am"), roles: [:cron] do
  runner "AppointmentNotification::ScheduleExperimentReminders.perfom_now"
end

every 2.minutes, roles: [:cron] do
  runner "TracerJob.perform_async(Time.current.iso8601, false)"
end

every 30.minutes, roles: [:cron] do
  runner "RegionsIntegrityCheck.sweep"
end

every 1.month, at: local("4:00 am"), roles: [:cron] do
  if Flipper.enabled?(:dhis2_export)
    rake "dhis2:export"
  end
end
