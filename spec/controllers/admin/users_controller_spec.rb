require 'rails_helper'

def login_user
  @request.env["devise.mapping"] = Devise.mappings[:admin]
  admin = FactoryBot.create(:admin)
  sign_in admin
end

RSpec.describe Admin::UsersController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # User. As you add validations to User, be sure to
  # adjust the attributes here as well.

  let(:facility) { FactoryBot.create(:facility) }
  let(:valid_attributes) {
    FactoryBot.attributes_for(:user).merge(registration_facility_id: facility.id)
  }

  let(:invalid_attributes) {
    FactoryBot.attributes_for(:user, facility_id: facility.id).merge(full_name: nil)
  }
  before(:each) do
    login_user
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # UsersController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe 'GET #index' do
    it 'returns a success response' do
      user = User.create! valid_attributes
      get :index, params: { facility_id: facility.id }
      expect(response).to be_success
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      user = User.create! valid_attributes
      get :show, params: { id: user.to_param, facility_id: facility.id }
      expect(response).to be_success
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      user = User.create! valid_attributes
      get :edit, params: { id: user.to_param, facility_id: facility.id }
      expect(response).to be_success
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) {
        FactoryBot.attributes_for(:user)
          .merge(registration_facility_id: facility.id)
          .except(:device_created_at, :device_updated_at, :otp, :otp_valid_until)
      }

      it 'updates the requested user' do
        user = User.create! valid_attributes
        put :update, params: { id: user.to_param, user: new_attributes, facility_id: facility.id }
        user.reload
        expect(user.attributes.except(
          'id', 'created_at', 'updated_at', 'deleted_at', 'device_created_at', 'device_updated_at',
          'password_digest', 'otp', 'otp_valid_until', 'access_token', 'logged_in_at'))
          .to eq new_attributes.with_indifferent_access.except('password', 'password_confirmation')
      end

      it 'redirects to the user' do
        user = User.create! valid_attributes
        put :update, params: { id: user.to_param, user: valid_attributes }
        expect(response).to redirect_to([:admin, user])
      end
    end

    context 'with invalid params' do
      it "returns a success response (i.e. to display the 'edit' template)" do
        user = User.create! valid_attributes
        put :update, params: { id: user.to_param, user: invalid_attributes, facility_id: facility.id }
        expect(response).to be_success
      end
    end
  end

  describe 'PUT #disable_access' do
    it 'disables the access token for the user' do
      user = User.create! valid_attributes
      put :disable_access, params: { user_id: user.id, facility_id: user.facility.id }
      user.reload
      expect(user.access_token_valid?).to be false
    end
  end

  describe 'PUT #enable_access' do
    let(:user) { FactoryBot.create(:user, registration_facility_id: facility.id) }

    it 'sets sync_approval_status to allowed' do
      put :enable_access, params: { user_id: user.id, facility_id: facility.id }
      user.reload
      expect(user.sync_approval_status_allowed?).to be true
    end
  end

  describe 'PUT #reset_otp' do
    let(:user) { FactoryBot.create(:user, registration_facility_id: facility.id) }

    before :each do
      sms_notification_service = double(SmsNotificationService.new(user))
      allow(SmsNotificationService).to receive(:new).with(user).and_return(sms_notification_service)
      expect(sms_notification_service).to receive(:send_request_otp_sms)
    end

    it 'resets OTP' do
      old_otp = user.otp
      put :reset_otp, params: { user_id: user.id, facility_id: facility.id }
      user.reload
      expect(user.otp_valid?).to be true
      expect(user.otp).not_to eq(old_otp)
    end
  end
end
