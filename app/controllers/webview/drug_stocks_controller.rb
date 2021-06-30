# This controller is meant to be used from webviews from the Android app _only_,
# hence we handle authentication ourselves from params passed from the client.
class Webview::DrugStocksController < ApplicationController
  include BustCache
  include SetForEndOfMonth

  skip_before_action :verify_authenticity_token
  around_action :set_time_zone
  before_action :authenticate
  before_action :find_current_facility
  before_action :set_show_current_month
  before_action :set_for_end_of_month
  before_action :set_bust_cache
  layout false

  def new
    @protocol_drugs = @current_facility.protocol.protocol_drugs.where(stock_tracked: true).sort_by(&:sort_key)
    @drug_stocks = DrugStock.latest_for_facilities_grouped_by_protocol_drug(current_facility, @for_end_of_month)
  end

  def create
    DrugStocksCreator.call(current_user, current_facility, @for_end_of_month, safe_params[:drug_stocks])
    redirect_to webview_drug_stocks_url(for_end_of_month: @for_end_of_month,
                                        facility_id: current_facility.id,
                                        user_id: current_user.id,
                                        access_token: current_user.access_token)
  rescue ActiveRecord::RecordInvalid => e
    logger.error "could not create DrugStocks - record invalid", errors: e.message
    render json: {status: "invalid", errors: e.message}, status: 422
  end

  def index
    @protocol_drugs = current_facility.protocol.protocol_drugs.where(stock_tracked: true).sort_by(&:sort_key)
    @drug_stocks = DrugStock.latest_for_facilities_grouped_by_protocol_drug(current_facility, @for_end_of_month)
    @query = DrugStocksQuery.new(facilities: [current_facility], for_end_of_month: @for_end_of_month)
    @drugs_by_category = @query.protocol_drugs_by_category
    @report = @query.drug_stocks_report
  end

  private

  attr_reader :current_facility, :current_user
  helper_method :current_facility, :current_user

  def fail_request(status, reason)
    logger.warn "API request failed due to #{reason}"
    head(status)
  end

  def authenticate
    user = User.find(safe_params[:user_id])
    if ActiveSupport::SecurityUtils.secure_compare(safe_params[:access_token], user.access_token)
      return fail_request(:forbidden, "sync_approval_status_allowed is false") unless user.sync_approval_status_allowed?
      login(user)
    else
      logger.warn "API request failed due to invalid access token"
      head(:unauthorized)
    end
  end

  def login(user)
    RequestStore.store[:current_user_id] = user.id
    user.mark_as_logged_in if user.has_never_logged_in?
    @current_user = user
  end

  def find_current_facility
    @current_facility = Facility.find(safe_params[:facility_id])
    if @current_facility.community?
      logger.error "Cannot create DrugStocks for community facility #{@current_facility.slug}"
      render json: {status: "invalid", errors: "community facility"}, status: 422
    end
  end

  def safe_params
    params.permit(:access_token, :facility_id, :user_id, :for_end_of_month,
      drug_stocks:
        [:received,
          :in_stock,
          :protocol_drug_id])
  end

  def set_bust_cache
    RequestStore.store[:bust_cache] = true if params[:bust_cache].present?
  end

  def set_time_zone
    Time.use_zone(Period::REPORTING_TIME_ZONE) { yield }
  end
end
