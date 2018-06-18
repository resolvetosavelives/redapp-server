class Api::V1::LoginsController < APIController
  before_action :validate_login_payload, only: %i[create]

  def create
    user = User.find_by(phone_number: login_params[:phone_number])

    errors = nil
    if !user.present?
      errors = { user: ['user is not present'] }
    elsif user.otp != login_params[:otp]
      errors = { user: ['otp is not valid'] }
    elsif user.otp_valid_until <= Time.now
      errors = { user: ['otp has expired'] }
    elsif !user.authenticate(login_params[:password])
      errors = { user: ['password is not valid'] }
    end

    if errors.present?
      render json: { errors: errors }, status: :unauthorized
    else
      render json: { user: Api::V1::Transformer.to_response(user) }, status: :ok
    end
  end

  private

  def validate_login_payload
    validator = Api::V1::UserLoginPayloadValidator.new(login_params)
    logger.debug "User login params had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      render json: { errors: validator.errors }, status: :unauthorized
    end
  end

  def login_params
    params.require(:user).permit(:phone_number, :password, :otp)
  end
end