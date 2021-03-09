require "features_helper"

RSpec.feature "test protocol detail page functionality", type: :feature do
  let(:owner) { create(:admin, :power_user) }
  let!(:var_protocol) { create(:protocol, name: "PunjabTestProtocol", follow_up_days: "20") }
  let!(:var_protocol_drug) { create(:protocol_drug, name: "test_Drug_01", dosage: "10mg", rxnorm_code: "code", protocol: var_protocol) }

  protocol = AdminPage::Protocols::Index.new
  protocol_show = AdminPage::Protocols::Show.new
  protocol_update = AdminPage::Protocols::Edit.new
  new_drug = AdminPage::ProtocolDrugs::New.new

  before(:each) do
    visit root_path
    sign_in(owner.email_authentication)
    visit admin_protocols_path
  end

  context "protocol show page" do
    it "edit protocol" do
      protocol.select_protocol(var_protocol.name)

      protocol_show.click_edit_protocol_button
      protocol_update.update_protocol_followup_days("10")

      # assertion
      protocol_show.verify_successful_message("Protocol was successfully updated.")
      protocol_show.verify_updated_followup_days("10")
      protocol_show.click_message_cross_button
    end

    it "should create new protocol drug " do
      protocol.select_protocol(var_protocol.name)

      protocol_show.click_new_protocol_drug_button
      new_drug.add_new_protocol_drug("test_drug", "10mg", "AXDSC")

      # assertion
      protocol_show.verify_successful_message("Protocol drug was successfully created.")
      expect(page).to have_content("test_drug")
    end

    it "should edit protocol drug" do
      protocol.select_protocol(var_protocol.name)
      protocol_show.click_edit_protocol_drug_button(var_protocol_drug.name)
      AdminPage::ProtocolDrugs::Edit.new.edit_protocol_drug_info("50mg", "AXDFC")
    end
  end
end
