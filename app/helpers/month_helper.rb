module MonthHelper
  def analytics_tz_month_start(year, month)
    Time.new(year, month).in_time_zone(ENV['ANALYTICS_TIME_ZONE'])
  end

  def month_short_name(month_start)
    month_start.strftime('%b')
  end

  def month_short_name_and_year(month_start)
    month_start.strftime('%b-%Y')
  end

  def last_n_months(n)
    (1..n).map do |i|
      Time.current.beginning_of_month - i.months
    end
  end
end
