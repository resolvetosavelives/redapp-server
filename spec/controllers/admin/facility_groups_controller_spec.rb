require "rails_helper"

RSpec.describe Admin::FacilityGroupsController, type: :controller do
  let(:organization) { FactoryBot.create(:organization) }
  let(:protocol) { FactoryBot.create(:protocol) }
  let(:valid_attributes) do
    FactoryBot.attributes_for(
      :facility_group,
      organization_id: organization.id,
      protocol_id: protocol.id
    )
  end

  let(:invalid_attributes) do
    FactoryBot.attributes_for(
      :facility_group,
      name: nil,
      organization_id: organization.id
    )
  end

  before do
    admin = create(:admin, :organization_owner, organization: organization)
    sign_in(admin.email_authentication)
  end

  describe "GET #show" do
    it "returns a success response" do
      facility_group = FacilityGroup.create! valid_attributes
      get :show, params: {id: facility_group.to_param, organization_id: organization.id}
      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {organization_id: organization.id}
      expect(response).to be_successful
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      facility_group = FacilityGroup.create! valid_attributes
      get :edit, params: {id: facility_group.to_param, organization_id: organization.id}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new FacilityGroup" do
        expect {
          post :create, params: {facility_group: valid_attributes, organization_id: organization.id}
        }.to change(FacilityGroup, :count).by(1)
      end

      it "redirects to the facilities" do
        post :create, params: {facility_group: valid_attributes, organization_id: organization.id}
        expect(response).to redirect_to(admin_facilities_url)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: {facility_group: invalid_attributes, organization_id: organization.id}
        expect(response).to be_successful
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) do
        FactoryBot.attributes_for(
          :facility_group,
          organization_id: organization.id,
          protocol_id: protocol.id
        ).except(:id, :slug)
      end

      it "updates the requested facility_group" do
        facility_group = FacilityGroup.create! valid_attributes
        put :update, params: {id: facility_group.to_param, facility_group: new_attributes, organization_id: organization.id}
        facility_group.reload
        expect(facility_group.attributes.except("id", "created_at", "updated_at", "deleted_at", "slug", "enable_diabetes_management"))
          .to eq new_attributes.with_indifferent_access
      end

      it "redirects to the facilities" do
        facility_group = FacilityGroup.create! valid_attributes
        put :update, params: {id: facility_group.to_param, facility_group: valid_attributes, organization_id: organization.id}
        expect(response).to redirect_to(admin_facilities_url)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        facility_group = FacilityGroup.create! valid_attributes
        put :update, params: {id: facility_group.to_param, facility_group: invalid_attributes, organization_id: organization.id}
        expect(response).to be_successful
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested facility_group" do
      facility_group = FacilityGroup.create! valid_attributes
      expect {
        delete :destroy, params: {id: facility_group.to_param, organization_id: organization.id}
      }.to change(FacilityGroup, :count).by(-1)
    end

    it "redirects to the facilities list" do
      facility_group = FacilityGroup.create! valid_attributes
      delete :destroy, params: {id: facility_group.to_param, organization_id: organization.id}
      expect(response).to redirect_to(admin_facilities_url)
    end
  end
end
