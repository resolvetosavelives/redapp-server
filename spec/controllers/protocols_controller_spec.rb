require 'rails_helper'

RSpec.describe ProtocolsController, type: :controller do

  let(:valid_attributes) {
    FactoryBot.attributes_for(:protocol)
  }

  let(:invalid_attributes) {
    FactoryBot.attributes_for(:protocol, name: nil)
  }

  describe "GET #index" do
    it "returns a success response" do
      protocol = Protocol.create! valid_attributes
      get :index, params: {}
      expect(response).to be_success
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      protocol = Protocol.create! valid_attributes
      get :show, params: {id: protocol.to_param}
      expect(response).to be_success
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {}
      expect(response).to be_success
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      protocol = Protocol.create! valid_attributes
      get :edit, params: {id: protocol.to_param}
      expect(response).to be_success
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Protocol" do
        expect {
          post :create, params: {protocol: valid_attributes}
        }.to change(Protocol, :count).by(1)
      end

      it "redirects to the created protocol" do
        post :create, params: {protocol: valid_attributes}
        expect(response).to redirect_to(Protocol.last)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: {protocol: invalid_attributes}
        expect(response).to be_success
      end
    end

  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        FactoryBot.attributes_for(:protocol).except(:id)
      }

      it "updates the requested protocol" do
        protocol = Protocol.create! valid_attributes
        put :update, params: {id: protocol.to_param, protocol: new_attributes}
        protocol.reload
        expect(response).to redirect_to(protocol)
        expect(protocol.attributes.except('id')).to eq new_attributes.with_indifferent_access
      end

      it "redirects to the protocol" do
        protocol = Protocol.create! valid_attributes
        put :update, params: {id: protocol.to_param, protocol: valid_attributes}
        expect(response).to redirect_to(protocol)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        protocol = Protocol.create! valid_attributes
        put :update, params: {id: protocol.to_param, protocol: invalid_attributes}
        expect(response).to be_success
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested protocol" do
      protocol = Protocol.create! valid_attributes
      expect {
        delete :destroy, params: {id: protocol.to_param}
      }.to change(Protocol, :count).by(-1)
    end

    it "redirects to the protocols list" do
      protocol = Protocol.create! valid_attributes
      delete :destroy, params: {id: protocol.to_param}
      expect(response).to redirect_to(protocols_url)
    end
  end
end
