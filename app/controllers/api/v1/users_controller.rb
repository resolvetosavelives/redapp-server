class Api::V1::UsersController < APIController
  skip_before_action :authenticate, only: [:register, :find, :request_otp]
  before_action :validate_registration_payload, only: %i[register]

  def register
    user = User.create(user_from_request)
    return render json: { errors: user.errors }, status: :bad_request if user.invalid?
    ApprovalNotifierMailer.with(user: user).approval_email.deliver_later
    render json: {
      user: user_to_response(user),
      access_token: user.access_token
    }, status: :ok
  end

  def find
    return head :bad_request unless find_params.present?
    user = User.find_by(find_params)
    return head :not_found unless user.present?
    render json: user_to_response(user), status: 200
  end

  def request_otp
    user = User.find(request_otp_id_param)
    user.set_otp
    user.save
    SmsNotificationService.new(user).send_request_otp_sms
    head :ok
  end

  private

  def user_from_request
    Api::V1::Transformer.from_request(registration_params)
      .merge(sync_approval_status: :requested)
  end

  def user_to_response(user)
    Api::V1::UserTransformer.to_response(user)
  end

  def validate_registration_payload
    validator = Api::V1::UserRegistrationPayloadValidator.new(registration_params)
    logger.debug "User registration params had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      render json: { errors: validator.errors }, status: :bad_request
    end
  end

  def registration_params
    params.require(:user)
      .permit(
        :id,
        :full_name,
        :phone_number,
        :password_digest,
        :updated_at,
        :created_at,
        facility_ids: [])
  end

  def find_params
    params.permit(:id, :phone_number)
  end

  def request_otp_id_param
    params.require(:id)
  end
end