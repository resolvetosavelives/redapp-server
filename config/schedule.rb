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
  runner "Reports::RegionCacheWarmer.call"
end

every :month, at: local("04:00 am"), roles: [:seed_data] do
  rake "db:purge_users_data"
  rake "db:seed_users_data"
end

every :monday, at: local("11:00 am"), roles: [:cron] do
  if Flipper.enabled?(:weekly_telemed_report)
    rake "reports:telemedicine"
  end
end
