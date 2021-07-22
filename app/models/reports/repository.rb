require_relative "experiment"
module Reports
  class Repository
    include BustCache
    include Memery
    include Scientist
    PERCENTAGE_PRECISION = 0

    def initialize(regions, periods:, reporting_schema_v2: true)
      @regions = Array(regions).map(&:region)
      @periods = if periods.is_a?(Period)
        Range.new(periods, periods)
      else
        periods
      end
      @period_type = @periods.first.type
      @reporting_schema_v2 = reporting_schema_v2
      raise ArgumentError, "Quarter periods not supported" if @period_type != :month

      @assigned_patients_query = AssignedPatientsQuery.new
      @bp_measures_query = BPMeasuresQuery.new
      @control_rate_query = ControlRateQuery.new
      @control_rate_query_v2 = ControlRateQueryV2.new
      @earliest_patient_data_query = EarliestPatientDataQuery.new
      @follow_ups_query = FollowUpsQuery.new
      @no_bp_measure_query = NoBPMeasureQuery.new
      @registered_patients_query = RegisteredPatientsQuery.new
    end

    attr_reader :assigned_patients_query
    attr_reader :bp_measures_query
    attr_reader :control_rate_query
    attr_reader :control_rate_query_v2
    attr_reader :earliest_patient_data_query
    attr_reader :follow_ups_query
    attr_reader :no_bp_measure_query
    attr_reader :period_type
    attr_reader :periods
    attr_reader :regions
    attr_reader :registered_patients_query

    def reporting_schema_v2?
      @reporting_schema_v2
    end

    delegate :cache, :logger, to: Rails

    # Returns the earliest patient record for a Region from either assigned or registered patients. Note that this *ignores*
    # the periods that are passed in for the Repository - this is the true 'earliest report date' for a Region.
    memoize def earliest_patient_recorded_at
      region_entries = regions.map { |region| RegionEntry.new(region, __method__) }
      cached_results = cache.fetch_multi(*region_entries, force: bust_cache?) { |region_entry|
        earliest_patient_data_query.call(region_entry.region)
      }
      cached_results.each_with_object({}) { |(region_entry, time), results| results[region_entry.slug] = time }
    end

    memoize def earliest_patient_recorded_at_period
      earliest_patient_recorded_at.each_with_object({}) { |(slug, time), hsh| hsh[slug] = Period.new(value: time, type: @period_type) if time }
    end

    # Returns assigned patients for a Region. NOTE: We grab and cache ALL the counts for a particular region with one SQL query
    # because it is easier and fast enough to do so. We still return _just_ the periods the Repository was created with
    # to conform to the same interface as all the other queries here.

    # Returns a Hash in the shape of:
    # {
    #    region_slug: { period: value, period: value },
    #    region_slug: { period: value, period: value }
    # }
    memoize def assigned_patients
      complete_monthly_assigned_patients.each_with_object({}) do |(entry, result), results|
        values = periods.each_with_object(Hash.new(0)) { |period, region_result| region_result[period] = result[period] if result[period] }
        results[entry.region.slug] = values
      end
    end

    # Adjusted patient counts are the patient counts from three months ago (the adjusted period) that
    # are the basis for control rates. These counts DO include lost to follow up.
    memoize def adjusted_patients_with_ltfu
      cumulative_assigned_patients.each_with_object({}) do |(entry, result), results|
        values = periods.each_with_object(Hash.new(0)) { |period, region_result|
          region_result[period] = result[period.adjusted_period]
        }
        results[entry] = values
      end
    end

    # Adjusted patient counts are the patient counts from three months ago (the adjusted period) that
    # are the basis for control rates. These counts DO NOT include lost to follow up.
    memoize def adjusted_patients_without_ltfu
      cumulative_assigned_patients.each_with_object({}) do |(entry, result), results|
        values = periods.each_with_object(Hash.new(0)) { |period, region_result|
          next unless result.key?(period.adjusted_period)
          region_result[period] = result[period.adjusted_period] - ltfu[entry][period]
        }
        results[entry] = values
      end
    end

    alias_method :adjusted_patients, :adjusted_patients_without_ltfu

    # Returns cumulative assigned patients from facility_states - this includes LTFU
    private def cumulative_assigned_patients_query_v2(region)
      Reports::FacilityState.for_facility(region).order(:month_date).pluck(:month_date, :assigned_patients)
    end

    # Return the running total of cumulative assigned patient counts. Note that this *includes* LTFU.
    memoize def cumulative_assigned_patients
      if reporting_schema_v2?
        regions.each_with_object({}) { |region, result|
          result[region.slug] = cumulative_assigned_patients_query_v2(region).each_with_object(Hash.new(0)) { |(month_date, count), hsh|
            hsh[Period.month(month_date)] = count
          }
        }
      else
        complete_monthly_assigned_patients.each_with_object({}) do |(region_entry, patient_counts), totals|
          slug = region_entry.slug
          next totals[slug] = Hash.new(0) if earliest_patient_recorded_at[slug].nil?
          range = Range.new(earliest_patient_recorded_at_period[slug], periods.end)
          totals[slug] = range.each_with_object(Hash.new(0)) { |period, sum|
            sum[period] = sum[period.previous] + patient_counts.fetch(period, 0)
          }
        end
      end
    end

    # Returns registration counts per region / period
    memoize def monthly_registrations
      complete_monthly_registrations.each_with_object({}) do |(entry, result), results|
        result.default = 0
        results[entry.region.slug] = result
      end
    end

    private def registered_patients_query_v2(region)
      Reports::FacilityState.for_facility(region).order(:month_date).pluck(:month_date, :monthly_registrations)
    end

    private def cumulative_registered_patients_query_v2(region)
      Reports::FacilityState.for_facility(region).order(:month_date).pluck(:month_date, :cumulative_registrations)
    end

    # Returns the full range of registered patient counts for a Region. We do this via one SQL query for each Region, because its
    # fast and easy via the underlying query.
    memoize def complete_monthly_registrations
      if reporting_schema_v2?
        regions.each_with_object({}) { |region, result|
          result[region.slug] = registered_patients_query_v2(region).each_with_object(Hash.new(0)) { |(month_date, count), hsh|
            hsh[Period.month(month_date)] = count
          }
        }
      else
        items = regions.map { |region| RegionEntry.new(region, __method__, period_type: period_type) }
        cache.fetch_multi(*items, force: bust_cache?) { |entry|
          registered_patients_query.count(entry.region, period_type)
        }
      end
    end

    memoize def cumulative_registrations
      if reporting_schema_v2?
        regions.each_with_object({}) { |region, result|
          result[region.slug] = cumulative_registered_patients_query_v2(region).each_with_object(Hash.new(0)) { |(month_date, count), hsh|
            hsh[Period.month(month_date)] = count
          }
        }
      else
        complete_monthly_registrations.each_with_object({}) do |(region_entry, patient_counts), totals|
          range = Range.new(patient_counts.keys.first || periods.first, periods.end)
          totals[region_entry.slug] = range.each_with_object(Hash.new(0)) { |period, sum|
            sum[period] = sum[period.previous] + patient_counts.fetch(period, 0)
          }
        end
      end
    end

    # Returns registration counts per region / period counted by registration_user
    memoize def monthly_registrations_by_user
      items = regions.map { |region| RegionEntry.new(region, __method__, group_by: :registration_user_id, period_type: period_type) }
      result = cache.fetch_multi(*items, force: bust_cache?) do |entry|
        registered_patients_query.count(entry.region, period_type, group_by: :registration_user_id)
      end
      result.each_with_object({}) { |(region_entry, counts), hsh|
        hsh[region_entry.region.slug] = counts
      }
    end

    private def ltfu_query_v2(region)
      Reports::FacilityState.for_facility(region).order(:month_date).pluck(:month_date, :lost_to_follow_up)
    end

    memoize def ltfu
      if reporting_schema_v2?
        regions.each_with_object({}) { |region, hsh|
          hsh[region.slug] = ltfu_query_v2(region).each_with_object(Hash.new(0)) { |(month_date, count), hsh|
            hsh[Period.month(month_date)] = count
          }
        }
      else
        region_period_cached_query(__method__) do |entry|
          facility_ids = entry.region.facility_ids
          Patient.for_reports.where(assigned_facility: facility_ids).ltfu_as_of(entry.period.end).count
        end
      end
    end

    memoize def ltfu_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(ltfu[slug][period], cumulative_assigned_patients[slug][period])
      end
    end

    memoize def controlled
      return controlled_v2 if reporting_schema_v2?
      science("controlled") do |e|
        e.use { controlled_v1 }
        e.try { controlled_v2 }
      end
    end

    private def controlled_v1
      region_period_cached_query(__method__) do |entry|
        control_rate_query.controlled(entry.region, entry.period).count
      end
    end

    private def controlled_v2
      regions.each_with_object({}).each do |region, hsh|
        if earliest_patient_recorded_at[region.slug].nil?
          hsh[region.slug] = Hash.new(0)
          next
        end
        hsh[region.slug] = control_rate_query_v2.controlled_counts(region, range: active_range(region))
      end
    end

    memoize def uncontrolled
      return uncontrolled_v2 if reporting_schema_v2?
      science("uncontrolled") do |e|
        e.use { uncontrolled_v1 }
        e.try { uncontrolled_v2 }
      end
    end

    private def uncontrolled_v1
      region_period_cached_query(__method__) do |entry|
        control_rate_query.uncontrolled(entry.region, entry.period).count
      end
    end

    private def uncontrolled_v2
      regions.each_with_object({}).each do |region, hsh|
        if earliest_patient_recorded_at[region.slug].nil?
          hsh[region.slug] = Hash.new(0)
          next
        end
        hsh[region.slug] = control_rate_query_v2.uncontrolled_counts(region, range: active_range(region))
      end
    end

    memoize def missed_visits_without_ltfu
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        patients = denominator(entry.region, entry.period)
        patients_with_visits = controlled[slug][period] + uncontrolled[slug][period] + visited_without_bp_taken[slug][period]
        patients - patients_with_visits
      end
    end

    # To determine the missed visits percentage, we sum the remaining percentages and subtract that from 100.
    # If we determined the percentage directly, we would have cases where the percentages do not add up to 100
    # due to rounding and losing precision.
    memoize def missed_visits_without_ltfu_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        visit_rates = controlled_rates[slug][period] + uncontrolled_rates[slug][period] + visited_without_bp_taken_rate[slug][period]
        100 - visit_rates
      end
    end

    memoize def missed_visits_with_ltfu
      region_period_cached_query(__method__, with_ltfu: true) do |entry|
        slug = entry.slug
        patients = denominator(entry.region, entry.period, with_ltfu: true)
        patients_with_visits = controlled[slug][entry.period] + uncontrolled[slug][entry.period] + visited_without_bp_taken[slug][entry.period]
        patients - patients_with_visits
      end
    end

    # To determine the missed visits percentage, we sum the remaining percentages and subtract that from 100.
    # If we determined the percentage directly, we would have cases where the percentages do not add up to 100
    # due to rounding and losing precision.
    memoize def missed_visits_with_ltfu_rates
      region_period_cached_query(__method__, with_ltfu: true) do |entry|
        slug, period = entry.slug, entry.period
        visit_rates = controlled_rates(with_ltfu: true)[slug][period] +
          uncontrolled_rates(with_ltfu: true)[slug][period] +
          visited_without_bp_taken_rate(with_ltfu: true)[slug][period]
        100 - visit_rates
      end
    end

    alias_method :missed_visits, :missed_visits_without_ltfu
    alias_method :missed_visits_rate, :missed_visits_without_ltfu_rates

    # Returns Follow ups per Region / Period. Takes an optional group_by clause (commonly used to group by `blood_pressures.user_id`)
    memoize def hypertension_follow_ups(group_by: nil)
      items = regions.map { |region| RegionEntry.new(region, __method__, group_by: group_by, period_type: period_type) }
      result = cache.fetch_multi(*items, force: bust_cache?) do |entry|
        follow_ups_query.hypertension(entry.region, period_type, group_by: group_by)
      end
      result.each_with_object({}) { |(region_entry, counts), hsh|
        hsh[region_entry.region.slug] = counts
      }
    end

    memoize def bp_measures_by_user
      items = regions.map { |region| RegionEntry.new(region, __method__, group_by: :user_id, period_type: period_type) }
      result = cache.fetch_multi(*items, force: bust_cache?) do |entry|
        bp_measures_query.count(entry.region, period_type, group_by: :user_id)
      end
      result.each_with_object({}) { |(region_entry, counts), hsh|
        hsh[region_entry.region.slug] = counts
      }
    end

    memoize def controlled_rates(with_ltfu: false)
      region_period_cached_query(__method__, with_ltfu: with_ltfu) do |entry|
        numerator = controlled[entry.slug][entry.period]
        total = denominator(entry.region, entry.period, with_ltfu: with_ltfu)
        percentage(numerator, total)
      end
    end

    memoize def uncontrolled_rates(with_ltfu: false)
      region_period_cached_query(__method__, with_ltfu: with_ltfu) do |entry|
        numerator = uncontrolled[entry.region.slug][entry.period]
        total = denominator(entry.region, entry.period, with_ltfu: with_ltfu)
        percentage(numerator, total)
      end
    end

    memoize def visited_without_bp_taken
      region_period_cached_query(__method__) do |entry|
        no_bp_measure_query.call(entry.region, entry.period)
      end
    end

    memoize def visited_without_bp_taken_rate(with_ltfu: false)
      region_period_cached_query(__method__, with_tlfu: with_ltfu) do |entry|
        numerator = visited_without_bp_taken[entry.slug][entry.period]
        total = denominator(entry.region, entry.period, with_ltfu: with_ltfu)
        percentage(numerator, total)
      end
    end

    private

    # Return the actual 'active range' for a Region - this will be the from the first recorded at in a region until
    # the end of the period range requested.
    def active_range(region)
      start = [earliest_patient_recorded_at_period[region.slug], periods.begin].compact.max
      (start..periods.end)
    end

    # Returns the full range of assigned patient counts for a Region. We do this via one SQL query for each Region, because its
    # fast and easy via the underlying query.
    memoize def complete_monthly_assigned_patients
      items = regions.map { |region| RegionEntry.new(region, __method__, period_type: period_type) }
      cache.fetch_multi(*items, force: bust_cache?) { |region_entry|
        assigned_patients_query.count(region_entry.region, period_type)
      }
    end

    def denominator(region, period, with_ltfu: false)
      if with_ltfu
        cumulative_assigned_patients[region.slug][period.adjusted_period]
      else
        cumulative_assigned_patients[region.slug][period.adjusted_period] - ltfu[region.slug][period]
      end
    end

    # Generate all necessary cache keys for a calculation, then yield to the block for every entry.
    # Once all results are returned via fetch_multi, return the data in a standard format of:
    #   {
    #     region_1_slug: { period_1: value, period_2: value }
    #     region_2_slug: { period_1: value, period_2: value }
    #   }
    #
    def region_period_cached_query(calculation, **options, &block)
      results = regions.each_with_object({}) { |region, hsh| hsh[region.slug] = Hash.new(0) }
      items = cache_entries(calculation, **options)
      cached_results = cache.fetch_multi(*items, force: bust_cache?) { |entry| block.call(entry) }
      cached_results.each { |(entry, count)| results[entry.region.slug][entry.period] = count }
      results
    end

    # Generate all necessary region period cache entries, only going back to the earliest
    # patient registration date for Periods. This ensures that we don't create many cache entries
    # with 0 data for newer Regions.
    def cache_entries(calculation, **options)
      combinations = regions.each_with_object([]) do |region, results|
        earliest_period = earliest_patient_recorded_at_period[region.slug]
        next if earliest_period.nil?
        periods_with_data = periods.select { |period| period >= earliest_period }
        results.concat(periods_with_data.to_a.map { |period| [region, period] })
      end
      combinations.map { |region, period| Reports::RegionPeriodEntry.new(region, period, calculation, options) }
    end

    def percentage(numerator, denominator)
      return 0 if denominator == 0 || numerator == 0
      ((numerator.to_f / denominator) * 100).round(PERCENTAGE_PRECISION)
    end
  end
end
