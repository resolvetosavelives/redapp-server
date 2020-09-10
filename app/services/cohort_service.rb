class CohortService
  CACHE_VERSION = 1
  CACHE_TTL = 7.days
  attr_reader :periods
  attr_reader :region

  def initialize(region:, periods:)
    @region = region
    @periods = periods
  end

  # Each quarter cohort is made up of patients registered in the previous quarter
  # who has had a follow up visit in the current quarter.
  def call
    periods.each_with_object([]) do |period, arry|
      arry << compute(period)
    end
  end

  private

  def compute(period)
    Rails.cache.fetch(cache_key(period), version: cache_version, expires_in: CACHE_TTL, force: force_cache?) do
      cohort_period = period.previous
      hsh = {cohort_period: cohort_period.type,
             registration_quarter: cohort_period.value.try(:number),
             registration_year: cohort_period.value.try(:year),
             registration_month: cohort_period.value.try(:month)}
      query = MyFacilities::BloodPressureControlQuery.new(facilities: region.facilities, cohort_period: hsh)
      {
        results_in: period.to_s,
        patients_registered: cohort_period.to_s,
        registered: query.cohort_registrations.count,
        controlled: query.cohort_controlled_bps.count,
        no_bp: query.cohort_missed_visits_count,
        uncontrolled: query.cohort_uncontrolled_bps.count
      }.with_indifferent_access
    end
  end

  def default_range
    Quarter.new(date: Date.current).downto(3)
  end

  def cache_key(period)
    "#{self.class}/#{region.model_name}/#{region.id}/#{period}"
  end

  def cache_version
    "#{region.updated_at.utc.to_s(:usec)}/#{CACHE_VERSION}"
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end
end
