# frozen_string_literal: true

class MyFacilitiesController < AdminController
  include DistrictFiltering
  include Pagination
  include MyFacilitiesFiltering
  include CohortPeriodSelection
  include PeriodSelection

  DEFAULT_ANALYTICS_TIME_ZONE = 'Asia/Kolkata'

  around_action :set_time_zone
  before_action :authorize_my_facilities
  before_action :set_selected_cohort_period, only: [:blood_pressure_control]
  before_action :populate_periods, :set_selected_period, only: [:registrations]

  def index
    @users_requesting_approval = paginate(policy_scope([:manage, :user, User])
                                            .requested_sync_approval
                                            .order(updated_at: :desc))

    @facilities = policy_scope([:manage, :facility, Facility])
    @inactive_facilities = MyFacilities::OverviewQuery.new(@facilities).inactive_facilities

    @facility_counts_by_size = { total: @facilities.group(:facility_size).count,
                                 inactive: @inactive_facilities.group(:facility_size).count }

    @inactive_facilities_bp_counts =
      { last_week: @inactive_facilities.bp_counts_in_period(start: 1.week.ago, finish: Time.current),
        last_month: @inactive_facilities.bp_counts_in_period(start: 1.month.ago, finish: Time.current) }
  end

  def blood_pressure_control
    @facilities = filter_facilities([:manage, :facility])

    bp_query = MyFacilities::BloodPressureControlQuery.new(cohort_period: @selected_cohort_period,
                                                           facilities: @facilities)

    @totals = { registered: bp_query.cohort_registrations.count,
                controlled: bp_query.cohort_controlled_bps.count,
                uncontrolled: bp_query.cohort_uncontrolled_bps.count,
                all_time_patients: bp_query.all_time_bps.count,
                all_time_controlled_bps: bp_query.all_time_controlled_bps.count }
    @totals[:missed] = missed_visits(@totals[:registered], @totals[:controlled], @totals[:uncontrolled])

    @registered_patients_per_facility = bp_query.cohort_registrations.group(:registration_facility_id).count
    @controlled_bps_per_facility = bp_query.cohort_controlled_bps.group(:bp_facility_id).count
    @uncontrolled_bps_per_facility = bp_query.cohort_uncontrolled_bps.group(:bp_facility_id).count
    @missed_visits_by_facility = @facilities.map do |f|
      [f.id, missed_visits(@registered_patients_per_facility[f.id].to_i,
                           @controlled_bps_per_facility[f.id].to_i,
                           @uncontrolled_bps_per_facility[f.id].to_i)]
    end.to_h
    @all_time_bps_per_facility = bp_query.all_time_bps.group(:bp_facility_id).count
    @all_time_controlled_bps_per_facility = bp_query.all_time_controlled_bps.group(:bp_facility_id).count
  end

  def registrations
    @facilities = filter_facilities([:manage, :facility])

    registrations_query = MyFacilities::RegistrationsQuery.new(period: @selected_period,
                                                               include_quarters: 3,
                                                               include_months: 3,
                                                               include_days: 14,
                                                               facilities: @facilities)

    @registrations = registrations_query.registrations
                         .group(:facility_id, :year, @selected_period)
                         .sum(:registration_count)

    @all_time_registrations = registrations_query.all_time_registrations.group(:bp_facility_id).count
    @display_periods = registrations_query.periods
  end

  private

  def set_time_zone
    time_zone = ENV['ANALYTICS_TIME_ZONE'] || DEFAULT_ANALYTICS_TIME_ZONE

    Time.use_zone(time_zone) { yield }
  end

  def authorize_my_facilities
    authorize(:dashboard, :show?)
  end

  def missed_visits(registered_patients, controlled_bps, uncontrolled_bps)
    registered_patients - controlled_bps - uncontrolled_bps
  end
end
