class Api::V1::SyncController < APIController
  before_action :validate_access_token

  def __sync_from_user__(params)
    errors = params.flat_map do |single_entity_params|
      merge_if_valid(single_entity_params) || []
    end

    capture_errors params, errors
    response = { errors: errors.nil? ? nil : errors }
    render json: response, status: :ok
  end

  def __sync_to_user__(response_key)
    records_to_sync = find_records_to_sync(processed_since, limit)
    render(
      json:   {
        response_key => records_to_sync.map { |record| transform_to_response(record) },
        'processed_since' => most_recent_record_timestamp(records_to_sync).strftime(TIME_WITHOUT_TIMEZONE_FORMAT)
      },
      status: :ok
    )
  end

  private

  def validate_access_token
    return unless FeatureToggle.is_enabled?('SYNC_API_AUTHENTICATION')
    user_id = request.headers["X_USER_ID"]
    user    = User.find_by(id: user_id)
    return head :unauthorized unless user.present? && user.access_token_valid?
    authenticate_or_request_with_http_token do |token, options|
      ActiveSupport::SecurityUtils.secure_compare(token, user.access_token)
    end
  end

  def params_with_errors(params, errors)
    error_ids = errors.map { |error| error[:id] }
    params
      .select { |param| error_ids.include? param[:id] }
      .map(&:to_hash)
  end

  def capture_errors(params, errors)
    return unless errors.present?

    Raven.capture_message(
      'Validation Error',
      logger: 'logger',
      extra:  {
        params_with_errors: params_with_errors(params, errors),
        errors: errors
      },
      tags: { type: 'validation' }
    )
  end

  def most_recent_record_timestamp(records_to_sync)
    if records_to_sync.empty?
      processed_since
    else
      records_to_sync.last.updated_at
    end
  end

  def processed_since
    params[:processed_since].try(:to_time) || Time.new(0)
  end

  def limit
    if params[:limit].present?
      params[:limit].to_i
    else
      ENV['DEFAULT_NUMBER_OF_RECORDS'].to_i
    end
  end
end
