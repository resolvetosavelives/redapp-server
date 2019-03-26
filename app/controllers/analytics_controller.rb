class AnalyticsController < AdminController
  before_action :set_analytics_timezone
  after_action :reset_analytics_timezone

  before_action :set_time_period, only: [:show]
  before_action :set_month, only: [:graphics]

  DEFAULT_ANALYTICS_TIMEZONE = 'New Delhi'

  def set_analytics_timezone
    Groupdate.time_zone = ENV['ANALYTICS_TIMEZONE'].present? ? ENV['ANALYTICS_TIMEZONE'] : DEFAULT_ANALYTICS_TIMEZONE
  end

  def reset_analytics_timezone
    Groupdate.time_zone = "UTC"
  end

  def set_time_period
    @from_time = params.require(:from_time).to_time
    @to_time = params.require(:to_time).to_time
  end

  def set_month
    month = params.require(:month).to_time
    @from_time = month.at_beginning_of_month
    @to_time = month.at_end_of_month
  end
end