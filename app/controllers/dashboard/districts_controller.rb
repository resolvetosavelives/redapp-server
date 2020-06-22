class Dashboard::DistrictsController < AdminController
  layout "application"
  skip_after_action :verify_policy_scoped
  around_action :set_time_zone

  EXAMPLE_DATA_FILE = "db/data/example_dashboard_data.json"

  def index
    authorize([:manage, FacilityGroup])
    @districts = policy_scope([:manage, FacilityGroup]).order(:name)
  end

  def show
    @district = FacilityGroup.find_by(slug: params[:id])
    authorize([:manage, @district])

    @district_name = @district.name

    @report_period = Date.current.advance(months: -1)

    @data = DistrictReportService.new(facilities: @district.facilities, selected_date: @report_period).call
    @controlled_patients = @data[:controlled_patients]
    @registrations = @data[:registrations]
    @quarterly_registrations = @data[:quarterly_registrations]
    render :preview
  end

  def preview
    authorize :dashboard, :view_my_facilities?

    @state_name = "Punjab"
    @district_name = "Bathinda"
    @report_period = Date.current
    @last_updated = "28-MAY-2020"
    # 20% Bathinda population
    @hypertensive_population = 277705

    example_data_file = File.read(EXAMPLE_DATA_FILE)
    @data = JSON.parse(example_data_file).with_indifferent_access
    @controlled_patients = @data[:controlled_patients]
    @registrations = @data[:registrations]
    @quarterly_registrations = @data[:quarterly_registrations]
  end

  private

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Time.use_zone(time_zone) { yield }
  end
end
