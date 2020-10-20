class FacilityAnalyticsQuery
  include DashboardHelper

  CACHE_VERSION = 1

  def initialize(facility, period = :month, prev_periods = 3, from_time = Time.current, include_current_period: false)
    @facility = facility
    @period = period
    @prev_periods = prev_periods
    @from_time = from_time
    @include_current_period = include_current_period
  end

  def call
    Rails.cache.fetch(cache_key, expires_in: ENV.fetch("ANALYTICS_DASHBOARD_CACHE_TTL"), force: force_cache?) do
      results
    end
  end

  def results
    results = [
      registered_patients_by_period,
      total_registered_patients,
      follow_up_patients_by_period
    ].compact

    return {} if results.blank?
    results.inject(&:deep_merge)
  end

  def total_registered_patients
    @total_registered_patients ||=
      @facility
        .registered_hypertension_patients
        .group("registration_user_id")
        .distinct("patients.id")
        .count

    return if @total_registered_patients.blank?

    @total_registered_patients
      .map { |user_id, count| [user_id, {total_registered_patients: count}] }
      .to_h
  end

  def registered_patients_by_period
    @registered_patients_by_period ||=
      @facility
        .registered_hypertension_patients
        .group("registration_user_id")
        .group_by_period(@period, :recorded_at)
        .distinct("patients.id")
        .count

    group_by_user_and_date(@registered_patients_by_period, :registered_patients_by_period)
  end

  def follow_up_patients_by_period
    #
    # this is similar to what the group_by_period query already gives us,
    # however, groupdate does not allow us to use these "groups" in a where clause
    # hence, we've replicated its grouping behaviour in order to remove the patients
    # that were registered prior to the period bucket
    #
    date_truncate_string =
      "(DATE_TRUNC('#{@period}', blood_pressures.recorded_at::timestamptz AT TIME ZONE '#{Groupdate.time_zone || 'Etc/UTC'}'))"

    @follow_up_patients_by_period ||=
      BloodPressure
        .left_outer_joins(:user)
        .left_outer_joins(:patient)
        .joins(:facility)
        .where(facility: @facility)
        .where(deleted_at: nil)
        .group('users.id')
        .group_by_period(@period, 'blood_pressures.recorded_at')
        .where("patients.recorded_at < #{date_truncate_string}")
        .order('users.id')
        .distinct
        .count('patients.id')

    group_by_user_and_date(@follow_up_patients_by_period, :follow_up_patients_by_period)
  end

  private

  def cache_key
    [
      self.class.name,
      @facility.id,
      @period,
      @prev_periods,
      @from_time.to_s(:mon_year),
      CACHE_VERSION
    ].join("/")
  end

  def group_by_user_and_date(query_results, key)
    valid_dates = dates_for_periods(@period,
      @prev_periods,
      from_time: @from_time,
      include_current_period: @include_current_period)

    query_results.map { |(user_id, date), value|
      {user_id => {key => {date.to_date => value}.slice(*valid_dates)}}
    }.inject(&:deep_merge)
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end
end
