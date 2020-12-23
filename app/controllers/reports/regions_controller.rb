class Reports::RegionsController < AdminController
  include Pagination
  include GraphicsDownload

  before_action :set_force_cache
  before_action :set_period, only: [:show, :details, :cohort]
  before_action :set_page, only: [:details]
  before_action :set_per_page, only: [:details]
  before_action :find_region, except: [:index]
  around_action :set_time_zone

  def index
    authorize { current_admin.accessible_facilities(:view_reports).any? }

    if current_admin.feature_enabled?(:regions_reports)
      @organizations = authorize {
        current_admin.accessible_facilities(:view_reports)
          .flat_map(&:organization)
          .uniq
          .compact
          .sort_by(&:name)
      }
    else
      accessible_facility_regions = authorize { current_admin.accessible_facility_regions(:view_reports) }
      @accessible_regions = accessible_facility_regions.each_with_object({}) { |facility, result|
        ancestors = Hash[facility.ancestors.map { |facility| [facility.region_type, facility] }]
        org, district, block = ancestors.values_at("organization", "district", "block")
        result[org] ||= {}
        result[org][district] ||= {}
        result[org][district][block] ||= []
        result[org][district][block] << facility
      }
    end
  end

  def show
    @data = Reports::RegionService.new(region: @region, period: @period).call
    @last_registration_value = @data[:cumulative_registrations].values&.last || 0
    @new_registrations = @last_registration_value - (@data[:cumulative_registrations].values[-2] || 0)
    @adjusted_registration_date = @data[:adjusted_registrations].keys[-4]

    if @region.respond_to?(:children)
      @children_data = @region.children.each_with_object({}) { |child, hsh|
        hsh[child.name] = Reports::RegionService.new(region: child,
                                                     period: @period).call
      }
    end
  end

  def details
    authorize { current_admin.accessible_facilities(:view_reports).any? }

    @show_current_period = true
    @dashboard_analytics = @region.dashboard_analytics(period: @period.type,
                                                       prev_periods: 6,
                                                       include_current_period: true)

    if @region.respond_to?(:recent_blood_pressures)
      @recent_blood_pressures = paginate(@region.recent_blood_pressures)
    end
  end

  def cohort
    authorize { current_admin.accessible_facilities(:view_reports).any? }
    periods = @period.downto(5)

    @cohort_data = CohortService.new(region: @region, periods: periods).call
  end

  def download
    authorize { current_admin.accessible_facilities(:view_reports).any? }
    @period = Period.new(type: params[:period], value: Date.current)
    unless @period.valid?
      raise ArgumentError, "invalid Period #{@period} #{@period.inspect}"
    end

    @cohort_analytics = @region.cohort_analytics(period: @period.type, prev_periods: 6)
    @dashboard_analytics = @region.dashboard_analytics(period: @period.type, prev_periods: 6)

    respond_to do |format|
      format.csv do
        if @region.is_a?(FacilityGroup) || @region.is_a?(FacilityDistrict)
          set_facility_keys
          send_data render_to_string("facility_group_cohort.csv.erb"), filename: download_filename
        else
          send_data render_to_string("cohort.csv.erb"), filename: download_filename
        end
      end
    end
  end

  def whatsapp_graphics
    authorize { current_admin.accessible_facilities(:view_reports).any? }

    previous_quarter = Quarter.current.previous_quarter
    @year, @quarter = previous_quarter.year, previous_quarter.number
    @quarter = params[:quarter].to_i if params[:quarter].present?
    @year = params[:year].to_i if params[:year].present?

    @cohort_analytics = @region.cohort_analytics(period: :quarter, prev_periods: 3)
    @dashboard_analytics = @region.dashboard_analytics(period: :quarter, prev_periods: 4)

    whatsapp_graphics_handler(
      @region.organization.name,
      @region.name
    )
  end

  private

  def accessible_district?(district)
    return true if current_admin.power_user?
    @accessible_district_ids ||= current_admin.accessible_district_regions(:view_reports).pluck(:id)
    @accessible_district_ids.include?(district.id)
  end

  def accessible_block?(block)
    return true if current_admin.power_user?
    @accessible_block_ids ||= current_admin.accessible_block_regions(:view_reports).pluck(:id)
    @accessible_block_ids.include?(block.id)
  end

  helper_method :accessible_district?
  helper_method :accessible_block?

  def download_filename
    time = Time.current.to_s(:number)
    region_name = @region.name.tr(" ", "-")
    "#{@region.class.to_s.underscore}-#{@period.adjective.downcase}-cohort-report_#{region_name}_#{time}.csv"
  end

  def set_facility_keys
    district = {
      id: :total,
      name: "Total"
    }.with_indifferent_access

    facilities = @region.facilities.order(:name).map { |facility|
      {
        id: facility.id,
        name: facility.name,
        type: facility.facility_type
      }.with_indifferent_access
    }

    @facility_keys = [district, *facilities]
  end

  def set_period
    period_params = report_params[:period].presence || Reports::RegionService.default_period.attributes
    @period = Period.new(period_params)
  end

  def set_force_cache
    RequestStore.store[:force_cache] = true if force_cache?
  end

  def find_region
    region_source = authorize {
      case region_class
      when "FacilityDistrict"
        scope = current_admin.accessible_facilities(:view_reports)
        FacilityDistrict.new(name: report_params[:id], scope: scope)
      when "FacilityGroup"
        current_admin.accessible_facility_groups(:view_reports).find_by!(slug: report_params[:id])
      when "Block" # we don't have first class auth on Blocks yet, so we authorize via the parent FacilityGroup
        block = Region.find_by!(slug: report_params[:id], region_type: "block")
        owning_facility_group = block.district_region.source
        unless current_admin.accessible_facility_groups(:view_reports).include?(owning_facility_group)
          raise UserAccess::NotAuthorizedError
        end
        block
      when "Facility"
        current_admin.accessible_facilities(:view_reports).find_by!(slug: params[:id])
      else
        raise ActiveRecord::RecordNotFound, "unknown region_class #{region_class}"
      end
    }
    @region = if current_admin.feature_enabled?(:region_reports)
      region_source.region
    else
      region_source
    end
  end

  def region_class
    @region_class ||= case report_params[:report_scope]
    when "facility_district"
      "facility_district"
    when "district"
      "facility_group"
    when "block"
      "block"
    when "facility"
      "facility"
    else
      raise ActiveRecord::RecordNotFound, "unknown report scope #{report_params[:report_scope]}"
    end.classify
  end

  def report_params
    params.permit(:id, :force_cache, :report_scope, {period: [:type, :value]})
  end

  def force_cache?
    report_params[:force_cache].present?
  end

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Groupdate.time_zone = time_zone

    Time.use_zone(time_zone) { yield }
    Groupdate.time_zone = "UTC"
  end
end
