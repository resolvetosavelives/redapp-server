module Reports
  class Result
    PERCENTAGE_PRECISION = 0

    def initialize(range)
      @range = range
      raise ArgumentError, "Beginning of range cannot be later than end of range" if range.begin > range.end
      @quarterly_report = @range.begin.quarter?
      @data = {
        adjusted_registrations: Hash.new(0),
        controlled_patients_rate: Hash.new(0),
        controlled_patients: Hash.new(0),
        cumulative_registrations: Hash.new(0),
        missed_visits_rate: {},
        missed_visits: {},
        period_info: {},
        registrations: Hash.new(0),
        uncontrolled_patients: Hash.new(0),
        uncontrolled_patients_rate: Hash.new(0)
      }.with_indifferent_access
    end

    attr_reader :range

    def []=(key, values)
      @data[key] = values
    end

    def [](key)
      @data[key]
    end

    def to_hash
      report_data
    end

    def report_data
      @report_data ||= @data.each_with_object({}) { |(key, hsh_or_array), report_data|
        report_data[key] = if !hsh_or_array.is_a?(Hash)
          hsh_or_array
        else
          hsh_or_array.slice(*range.entries)
        end
      }.with_indifferent_access
    end

    def merge!(other)
      @data.merge! other
    end

    def last_value(key)
      self[key].values.last
    end

    [:adjusted_registrations, :controlled_patients, :controlled_patients_rate, :cumulative_registrations,
      :missed_visits, :missed_visits_rate, :period_info, :registrations, :uncontrolled_patients,
      :uncontrolled_patients_rate, :visited_without_bp_taken, :visited_without_bp_taken_rate].each do |key|
      define_method(key) do
        self[key]
      end

      setter = "#{key}="
      define_method(setter) do |value|
        self[key] = value
      end

      define_method("#{key}_for") do |period|
        self[key][period]
      end
    end

    # Adjusted registrations are the registrations as of three months ago - we use these for all the percentage
    # calculations to exclude recent registrations.
    def count_adjusted_registrations
      self.adjusted_registrations = range.each_with_object(Hash.new(0)) do |period, hsh|
        hsh[period] = cumulative_registrations_for(period.advance(months: -3))
      end
    end

    # "Missed visits" is the remaining registerd patients when we subtract out the other three groups.
    def count_missed_visits
      self.missed_visits = range.each_with_object({}) { |(period, visit_count), hsh|
        registrations = adjusted_registrations_for(period)
        controlled = controlled_patients_for(period)
        uncontrolled = uncontrolled_patients_for(period)
        visited_without_bp_taken = visited_without_bp_taken_for(period)
        hsh[period] = registrations - visited_without_bp_taken - controlled - uncontrolled
      }
    end

    # To determine the missed visits percentage, we sum the remaining percentages and subtract that from 100.
    # If we determined the percentage directly, we would have cases where the percentages do not add up to 100
    # due to rounding and losing precision.
    def calculate_missed_visits_percentages
      self.missed_visits_rate = range.each_with_object({}) do |period, hsh|
        remaining_percentages = controlled_patients_rate_for(period) + uncontrolled_patients_rate_for(period) + visited_without_bp_taken_rate_for(period)
        hsh[period] = 100 - remaining_percentages
      end
    end

    DATE_FORMAT = "%-d-%b-%Y"
    def calculate_period_info
      self.period_info = range.each_with_object({}) do |period, hsh|
        range = period.blood_pressure_control_range
        hsh[period] = {
          bp_control_start_date: range.begin.next_day.strftime(DATE_FORMAT),
          bp_control_end_date: range.end.strftime(DATE_FORMAT)
        }
      end
    end

    def registrations_for_percentage_calculation(period)
      if quarterly_report?
        self[:registrations][period.previous] || 0
      else
        adjusted_registrations_for(period)
      end
    end

    def calculate_percentages(key)
      key_for_percentage_data = "#{key}_rate"
      self[key_for_percentage_data] = self[key].each_with_object(Hash.new(0)) { |(period, value), hsh|
        hsh[period] = percentage(value, registrations_for_percentage_calculation(period))
      }
    end

    def quarterly_report?
      @quarterly_report
    end

    def percentage(numerator, denominator)
      return 0 if denominator == 0 || numerator == 0
      ((numerator.to_f / denominator) * 100).round(PERCENTAGE_PRECISION)
    end
  end
end
