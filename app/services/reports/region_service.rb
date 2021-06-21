module Reports
  class RegionService
    # The default period we report on is the current month.
    def self.default_period
      Period.month(Time.current.in_time_zone(Period::REPORTING_TIME_ZONE))
    end

    def self.call(*args)
      new(*args).call
    end

    def initialize(region:, period:, months: MAX_MONTHS_OF_DATA)
      @current_user = current_user
      @region = region
      @period = period
      start_period = period.advance(months: -(months - 1))
      @range = Range.new(start_period, @period)
    end

    attr_reader :current_user
    attr_reader :result
    attr_reader :period
    attr_reader :range
    attr_reader :region

    def call
      result = Reports::Result.new(region: @region, period_type: @report_range.begin.type)
      result.earliest_registration_period = repository.earliest_patient_recorded_at_period[slug]
      result.registrations = repository.monthly_registrations[slug]
      result.assigned_patients = repository.assigned_patients[slug]
      result.cumulative_registrations = repository.cumulative_registrations[slug]
      result.cumulative_assigned_patients = repository.cumulative_assigned_patients[slug]
      result.adjusted_patient_counts_with_ltfu = repository.adjusted_patients_with_ltfu[slug]
      result.adjusted_patient_counts = repository.adjusted_patients_without_ltfu[slug]
      result.ltfu_patients = repository.ltfu[slug]

      result.controlled_patients = repository.controlled[slug]
      result.uncontrolled_patients = repository.uncontrolled[slug]

      result.controlled_patients_rate = repository.controlled_rates[slug]
      result.uncontrolled_patients_rate = repository.uncontrolled_rates[slug]
      result.controlled_patients_with_ltfu_rate = repository.controlled_rates(with_ltfu: true)[slug]
      result.uncontrolled_patients_with_ltfu_rate = repository.uncontrolled_rates(with_ltfu: true)[slug]
      result.ltfu_patients_rate = repository.ltfu_rates[slug]

      result.visited_without_bp_taken = repository.visited_without_bp_taken[region.slug]
      result.calculate_percentages(:visited_without_bp_taken)
      result.calculate_percentages(:visited_without_bp_taken, with_ltfu: true)

      # missed visits without ltfu
      result.missed_visits = repository.missed_visits[region.slug]
      result.missed_visits_rate = repository.missed_visits_without_ltfu_rates[region.slug]
      # missed visits with ltfu
      result.missed_visits_with_ltfu = repository.missed_visits_with_ltfu[region.slug]
      result.missed_visits_with_ltfu_rate = repository.missed_visits_with_ltfu_rates[region.slug]

      start_period = [repository.earliest_patient_recorded_at_period[region.slug], range.begin].compact.max
      calc_range = (start_period..range.end)
      result.period_info = calc_range.each_with_object({}) { |period, hsh| hsh[period] = period.to_hash }

      result
    end

    private

    def repository
      @repository ||= Reports::Repository.new(region, periods: range)
    end

    # We want the current quarter and then the previous four
    def last_five_quarters
      period.to_quarter_period.value.downto(4)
    end
  end
end
