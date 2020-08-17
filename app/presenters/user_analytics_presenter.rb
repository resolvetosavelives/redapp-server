class UserAnalyticsPresenter < Struct.new(:current_facility)
  include ApplicationHelper
  include DayHelper
  include PeriodHelper
  include DashboardHelper

  DAYS_AGO = 30
  MONTHS_AGO = 6
  TROPHY_MILESTONES = [10, 25, 50, 100, 250, 500, 1_000, 2_000, 3_000, 4_000, 5_000]
  TROPHY_MILESTONE_INCR = 10_000
  EXPIRE_STATISTICS_CACHE_IN = 15.minutes

  def daily_stats_by_date(stat, day_date)
    zero_if_unavailable statistics.dig(:daily, :grouped_by_date, stat, day_date)
  end

  def monthly_htn_stats_by_date(stat, month_date)
    zero_if_unavailable statistics.dig(:monthly, :grouped_by_date, :hypertension, stat, month_date)
  end

  def monthly_dm_stats_by_date(stat, month_date)
    zero_if_unavailable statistics.dig(:monthly, :grouped_by_date, :diabetes, stat, month_date)
  end

  def monthly_htn_or_dm_stats_by_date(stat, month_date)
    zero_if_unavailable statistics.dig(:monthly, :grouped_by_date, :htn_or_dm, stat, month_date)
  end

  def monthly_htn_control_rate(month_date)
    display_percentage(monthly_htn_stats_by_date(:controlled_visits, month_date),
      monthly_htn_stats_by_date(:follow_ups, month_date))
  end

  def monthly_dm_stats_by_date_and_gender(stat, month_date, gender)
    zero_if_unavailable statistics.dig(:monthly, :grouped_by_date_and_gender, :diabetes, stat, [month_date, gender])
  end

  def monthly_htn_stats_by_date_and_gender(stat, month_date, gender)
    zero_if_unavailable statistics.dig(:monthly, :grouped_by_date_and_gender, :hypertension, stat, [month_date, gender])
  end

  def all_time_htn_or_dm_count(stat)
    zero_if_unavailable statistics.dig(:all_time, :grouped_by_date, :htn_or_dm, stat)
  end

  def all_time_dm_count(stat)
    zero_if_unavailable statistics.dig(:all_time, :grouped_by_gender, :diabetes, stat).values.sum
  end

  def all_time_htn_count(stat)
    zero_if_unavailable statistics.dig(:all_time, :grouped_by_gender, :hypertension, stat).values.sum
  end

  def all_time_dm_stats_by_gender(stat, gender)
    zero_if_unavailable statistics.dig(:all_time, :grouped_by_gender, :diabetes, stat, gender)
  end

  def all_time_htn_stats_by_gender(stat, gender)
    zero_if_unavailable statistics.dig(:all_time, :grouped_by_gender, :hypertension, stat, gender)
  end

  def locked_trophy
    statistics.dig(:trophies, :locked_trophy_value)
  end

  def unlocked_trophies
    statistics.dig(:trophies, :unlocked_trophy_values)
  end

  def achievements?
    statistics.dig(:trophies, :locked_trophy_value) > TROPHY_MILESTONES.first
  end

  def diabetes_enabled?
    FeatureToggle.enabled?("DIABETES_SUPPORT_IN_PROGRESS_TAB") && current_facility.diabetes_enabled?
  end

  def daily_period_list
    period_list_as_dates(:day, DAYS_AGO)
  end

  def monthly_period_list
    period_list_as_dates(:month, MONTHS_AGO)
  end

  def display_percentage(numerator, denominator)
    return "0%" if denominator.nil? || denominator.zero? || numerator.nil?
    percentage = (numerator * 100.0) / denominator

    "#{percentage.round(0)}%"
  end

  def last_updated_at
    statistics.dig(:metadata, :last_updated_at)
  end

  def statistics
    @statistics ||=
      Rails.cache.fetch(statistics_cache_key, expires_in: EXPIRE_STATISTICS_CACHE_IN) {
        {
          daily: daily_stats,
          monthly: monthly_stats,
          all_time: all_time_stats,
          trophies: trophy_stats,
          metadata: {
            is_diabetes_enabled: diabetes_enabled?,
            last_updated_at: I18n.l(Time.current),
            formatted_next_date: display_date(Time.current + 1.day),
            today_string: I18n.t(:today_str)
          }
        }
      }
  end

  private

  def daily_stats
    diabetes_enabled? ? daily_htn_or_dm_stats : daily_htn_stats
  end

  def daily_htn_stats
    follow_ups =
      current_facility
        .hypertension_follow_ups_by_period(:day, last: DAYS_AGO)
        .count

    registrations =
      current_facility
        .registered_hypertension_patients
        .group_by_period(:day, :recorded_at, last: DAYS_AGO)
        .count

    {
      grouped_by_date:
        {
          follow_ups: follow_ups,
          registrations: registrations
        }
    }
  end

  def daily_htn_or_dm_stats
    follow_ups =
      current_facility
        .patient_follow_ups_by_period(:day, last: DAYS_AGO)
        .count

    registrations =
      current_facility
        .registered_patients
        .group_by_period(:day, :recorded_at, last: DAYS_AGO)
        .count

    {
      grouped_by_date:
        {
          follow_ups: follow_ups,
          registrations: registrations
        }
    }
  end

  def monthly_stats
    return monthly_htn_stats unless diabetes_enabled?

    [monthly_htn_or_dm_stats,
      monthly_htn_stats,
      monthly_dm_stats].inject(:deep_merge)
  end

  def all_time_stats
    return all_time_htn_stats unless diabetes_enabled?

    [all_time_htn_or_dm_stats,
      all_time_htn_stats,
      all_time_dm_stats].inject(:deep_merge)
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
    follow_up_count = all_time_htn_stats.dig(:grouped_by_gender, :hypertension, :follow_ups).values.sum
    milestones = trophy_milestones(follow_up_count)
    locked_milestone_idx = milestones.index { |milestone| follow_up_count < milestone }

    {
      locked_trophy_value:
        milestones[locked_milestone_idx],

      unlocked_trophy_values:
        milestones[0, locked_milestone_idx]
    }
  end

  def trophy_milestones(follow_up_count)
    if follow_up_count >= TROPHY_MILESTONES.last
      [*TROPHY_MILESTONES,
        *(TROPHY_MILESTONE_INCR..(follow_up_count + TROPHY_MILESTONE_INCR)).step(TROPHY_MILESTONE_INCR)]
    else
      TROPHY_MILESTONES
    end
  end

  def monthly_htn_or_dm_stats
    follow_ups =
      current_facility
        .patient_follow_ups_by_period(:month, last: MONTHS_AGO)
        .count

    registrations =
      current_facility
        .registered_patients
        .group_by_period(:month, :recorded_at, last: MONTHS_AGO)
        .count

    {
      grouped_by_date: {
        htn_or_dm: {
          follow_ups: follow_ups,
          registrations: registrations
        }
      }
    }
  end

  def monthly_htn_stats
    follow_ups =
      current_facility
        .hypertension_follow_ups_by_period(:month, last: MONTHS_AGO)
        .group(:gender)
        .count

    controlled_visits =
      current_facility
        .hypertension_follow_ups_by_period(:month, last: MONTHS_AGO)
        .merge(BloodPressure.under_control)
        .count

    registrations =
      current_facility
        .registered_hypertension_patients
        .group_by_period(:month, :recorded_at, last: MONTHS_AGO)
        .group(:gender)
        .count

    {
      grouped_by_date_and_gender: {
        hypertension: {
          follow_ups: follow_ups,
          registrations: registrations
        }
      },

      grouped_by_date: {
        hypertension: {
          follow_ups: sum_by_date(follow_ups),
          controlled_visits: controlled_visits.to_hash,
          registrations: sum_by_date(registrations)
        }
      }
    }
  end

  def monthly_dm_stats
    follow_ups =
      current_facility
        .diabetes_follow_ups_by_period(:month, last: MONTHS_AGO)
        .group(:gender)
        .count

    registrations =
      current_facility
        .registered_diabetes_patients
        .group_by_period(:month, :recorded_at, last: MONTHS_AGO)
        .group(:gender)
        .count

    {
      grouped_by_date_and_gender: {
        diabetes: {
          follow_ups: follow_ups,
          registrations: registrations
        }
      },

      grouped_by_date: {
        diabetes: {
          follow_ups: sum_by_date(follow_ups),
          registrations: sum_by_date(registrations)
        }
      }
    }
  end

  def all_time_htn_or_dm_stats
    follow_ups =
      current_facility
        .patient_follow_ups_by_period(:month)
        .count
        .values
        .sum

    registrations =
      current_facility
        .registered_patients
        .count

    {
      grouped_by_date: {
        htn_or_dm: {
          follow_ups: follow_ups,
          registrations: registrations
        }
      }
    }
  end

  def all_time_htn_stats
    follow_ups =
      sum_by_gender(current_facility
                      .hypertension_follow_ups_by_period(:month)
                      .group(:gender)
                      .count)

    registrations =
      current_facility
        .registered_hypertension_patients
        .group(:gender)
        .count

    {
      grouped_by_gender: {
        hypertension: {
          follow_ups: follow_ups,
          registrations: registrations
        }
      }
    }
  end

  def all_time_dm_stats
    follow_ups =
      sum_by_gender(current_facility
                      .diabetes_follow_ups_by_period(:month)
                      .group(:gender)
                      .count)

    registrations =
      current_facility
        .registered_diabetes_patients
        .group(:gender)
        .count

    {
      grouped_by_gender: {
        diabetes: {
          follow_ups: follow_ups,
          registrations: registrations
        }
      }
    }
  end

  def statistics_cache_key
    "user_analytics/#{current_facility.id}"
  end

  def sum_by_date(data)
    data.each_with_object({}) do |((date, _), count), by_date|
      by_date[date] ||= 0
      by_date[date] += count
    end
  end

  def sum_by_gender(data)
    data.each_with_object({}) do |((_, gender), count), by_gender|
      by_gender[gender] ||= 0
      by_gender[gender] += count
    end
  end
end
