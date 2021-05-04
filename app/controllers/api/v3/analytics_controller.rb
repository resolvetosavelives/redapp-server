class Api::V3::AnalyticsController < APIController
  around_action :set_time_zone

  private

  def set_time_zone
    time_zone = CountryConfig.current[:time_zone] || Period::DEFAULT_ANALYTICS_TIME_ZONE

    Groupdate.time_zone = time_zone

    Time.use_zone(time_zone) do
      yield
    end
  ensure
    Groupdate.time_zone = "UTC"
  end
end
