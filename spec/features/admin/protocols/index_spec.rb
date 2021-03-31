require "features_helper"

RSpec.feature "test protocol screen functionality", type: :feature do
  let(:owner) { create(:admin, :power_user) }
  let!(:var_protocol) { create(:protocol, name: "PunjabTestProtocol", follow_up_days: "20") }

  protocol_new = AdminPage::Protocols::New.new
  protocol_page = AdminPage::Protocols::Index.new
  protocol_show = AdminPage::Protocols::Show.new

  before(:each) do
    visit root_path
    sign_in(owner.email_authentication)
    visit admin_protocols_path
  end

  context "protocol landing page" do
    it "add new  protocol" do
      protocol_page.click_add_new_protocol
      protocol_new.create_new_protocol("testProtocol", "40")

      protocol_show.verify_successful_message("Protocol was successfully created.")
      protocol_show.click_message_cross_button

      expect(page).to have_content("TestProtocol")
    end

    it "edit protocol" do
      protocol_page.click_edit_protocol_link(var_protocol.name)
      AdminPage::Protocols::Edit.new.update_protocol_followup_days(40)
      protocol_show.verify_updated_followup_days("40")

      visit admin_protocols_path

      # assertion at landing page
      within(:xpath, "//div[@id='" + var_protocol.name + "']") do
        expect(page).to have_content("Edit")
        expect(page).to have_selector("a.btn-outline-danger")
        expect(page).to have_content("40")
      end
    end
  end
end
