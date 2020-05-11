class Api::V4::UserTransformer
  class << self
    def to_response(user)
      Api::V4::Transformer.to_response(user)
        .merge('registration_facility_id' => user.registration_facility.id,
               'phone_number' => user.phone_number,
               'password_digest' => user.phone_number_authentication.password_digest)
        .except('otp', 'otp_expires_at', 'access_token', 'logged_in_at', 'role', 'organization_id')
    end

    def to_find_response(user)
      to_response(user).slice('id', 'sync_approval_status')
    end
  end
end
