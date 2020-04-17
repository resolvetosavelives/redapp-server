class UserAnalyticsPresenter
  include ApplicationHelper
  include HashUtilities
  include MonthHelper
  include DayHelper
  include PeriodHelper

  DAYS_AGO = 30
  MONTHS_AGO = 6
  TROPHY_MILESTONES = [10, 25, 50, 100, 250, 500, 1_000, 2_000, 3_000, 4_000, 5_000]
  TROPHY_MILESTONE_INCR = 10_000

  attr_reader :daily_period_list, :monthly_period_list

  def initialize(current_facility)
    @current_facility = current_facility
    @daily_period_list = period_list_as_dates(:day, DAYS_AGO)
    @monthly_period_list = period_list_as_dates(:month, MONTHS_AGO)

    @last_refreshed_at =
      Rails.cache.fetch(Rails.application.config.app_constants[:MATVIEW_REFRESH_TIME_KEY]).presence || Time.current

    @user_analytics = UserAnalyticsQuery.new(current_facility,
                                             days_ago: DAYS_AGO,
                                             months_ago: MONTHS_AGO,
                                             fetch_until: @last_refreshed_at)
  end

  def statistics
    @statistics ||=
      Rails.cache.fetch(statistics_cache_key) do
        {
          daily: daily_stats,
          monthly: monthly_stats,
          all_time: all_time_stats,
          trophies: trophy_stats,
          metadata: {
            is_diabetes_enabled: false,
            last_updated_at: I18n.l(@last_refreshed_at),
            formatted_next_date: display_date(@last_refreshed_at + 1.day),
            today_string: I18n.t(:today_str)
          }
        }
      end
  end

  def stats_across_genders_for_month(resource, month_date)
    data_for_resource = statistics.dig(:monthly, :grouped_by_gender_and_date, resource).values

    sum_across_gender_and_months =
      data_for_resource.inject do |by_month, count_for_gender|
        by_month.merge(count_for_gender) { |_, v1, v2| v1 + v2 }
      end

    sum_across_gender_and_months&.dig(month_date)
  end

  def display_percentage(numerator, denominator)
    return '0%' if denominator.nil? || denominator.zero? || numerator.nil?
    percentage = (numerator * 100.0) / denominator

    "#{percentage.round(0)}%"
  end

  private

  def daily_follow_ups
    last_n_periods(:day, DAYS_AGO).map do |date|
      [date, @current_facility.followed_up(:day, date).count]
    end.to_h
  end

  def monthly_follow_ups
    last_n_periods(:month, MONTHS_AGO).map do |date|
      [date.to_date, @current_facility.followed_up(:month, date.to_date).group(:gender).count]
    end.to_h
  end

  def monthly_visits
    last_n_periods(:month, MONTHS_AGO).map do |date|
      [date.to_date, @current_facility.followed_up(:month, date.to_date).count]
    end.to_h
  end

  def controlled_visits
    last_n_periods(:month, MONTHS_AGO).map do |date|
      [date.to_date, @current_facility.followed_up(:month, date.to_date).merge(BloodPressure.under_control).count]
    end.to_h
  end

  def all_time_follow_ups
    @current_facility.all_follow_ups.group(:gender).count
  end

  def daily_registrations
    @current_facility
      .registered_patients
      .group_by_period(:day, :recorded_at, last: DAYS_AGO)
      .count
  end

  def monthly_registrations
    last_n_periods(:month, MONTHS_AGO).map do |date|
      [date.to_date, @current_facility.registered_patients.where(recorded_at: date.all_month).group(:gender).count]
    end.to_h
  end

  def all_time_registrations
    @current_facility
      .registered_patients
      .group(:gender)
      .count
  end

  def daily_stats
    {
      grouped_by_date:
        {
          follow_ups: daily_follow_ups,
          registrations: daily_registrations
        }
    }
  end

  def monthly_stats
    {
      grouped_by_gender_and_date:
        {
          follow_ups: monthly_follow_ups,
          registrations: monthly_registrations
        },

      grouped_by_date:
        {
          total_visits: monthly_visits,
          controlled_visits: controlled_visits,
        }
    }
  end

  def all_time_stats
    {
      grouped_by_gender:
        {
          follow_ups: all_time_follow_ups,
          registrations: all_time_registrations
        }
    }
  end

  #
  # After exhausting the initial TROPHY_MILESTONES, subsequent milestones must follow the following pattern:
  #
  # 10
  # 25
  # 50
  # 100
  # 250
  # 500
  # 1_000
  # 2_000
  # 3_000
  # 4_000
  # 5_000
  # 10_000
  # 20_000
  # 30_000
  # etc.
  #
  # i.e. increment by TROPHY_MILESTONE_INCR
  def trophy_stats
    total_follow_ups = MyFacilities::FollowUpsQuery.new(facilities: @current_facility).total_follow_ups.count

    all_trophies =
      total_follow_ups > TROPHY_MILESTONES.last ?
        [*TROPHY_MILESTONES,
         *(TROPHY_MILESTONE_INCR..(total_follow_ups + TROPHY_MILESTONE_INCR)).step(TROPHY_MILESTONE_INCR)] :
        TROPHY_MILESTONES

    unlocked_trophies_until = all_trophies.index { |v| total_follow_ups < v }

    {
      locked_trophy_value:
        all_trophies[unlocked_trophies_until],

      unlocked_trophy_values:
        all_trophies[0, unlocked_trophies_until]
    }
  end

  #
  # Groups by gender+date in the following format,
  #
  # { :grouped_by_gender_and_date =>
  #    { "male" =>
  #        { "Sun, 01 Mar 2020" => 21 ,
  #          "Tue, 01 Oct 2019" => 0 },
  #      "female" =>
  #        { "Sun, 01 Mar 2020" => 18,
  #          "Tue, 01 Oct 2019" => 0 } } }
  #
  def group_by_date_and_gender(resource_data)
    resource_data.inject(autovivified_hash) do |by_gender_and_date, ((date, gender), resource)|
      by_gender_and_date[date][gender] = resource
      by_gender_and_date
    end
  end

  def data_for_unavailable_dates(period_list)
    period_list.map { |date| [date, 0] }.to_h
  end

  def statistics_cache_key
    "user_analytics/#{@current_facility.id}/#{@last_refreshed_at}"
  end
end
