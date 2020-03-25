class Api::V4::UsersController < APIController
  skip_before_action :current_user_present?, only: [:find]
  skip_before_action :validate_sync_approval_status_allowed, only: [:find]
  skip_before_action :authenticate, only: [:find]
  skip_before_action :validate_facility, only: [:find]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:find]

  def find
    return head :bad_request unless params[:phone_number].present?
    user = PhoneNumberAuthentication.find_by(phone_number: params[:phone_number])&.user
    return head :not_found unless user.present?
    render json: { user: to_find_response(user) }, status: :ok
  end

  private

  def to_find_response(user)
    Api::V4::UserTransformer.to_find_response(user)
  end
end
