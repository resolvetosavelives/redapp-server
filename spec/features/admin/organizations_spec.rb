require 'rails_helper'

RSpec.feature 'Organization management', type: :feature do
    let!(:owner) { create(:admin, :owner) }
    let!(:ihmi) { create(:organization, name: "IHMI") }
    let!(:path) { create(:organization, name: "PATH") }
    login = LoginPage.new
    homepage = HomePage.new

    describe "test organization screen" do

      it 'Verify organisation is displayed in ManageOrganisation' do
        visit root_path
        login.do_login(owner.email, owner.password)

        homepage.select_main_menu_tab("Manage")
        expect(page).to have_content("Organizations")
        expect(page).to have_content("Protocols")

        homepage.select_manage_option('Organizations')
        expect(page).to have_content("IHMI")
        expect(page).to have_content("PATH")
      end

      it 'Verify owner should be able to delete organisation ' do
        visit root_path
        login.do_login(owner.email, owner.password)

        homepage.select_manage_option("Organizations")
        organization = OrganizationsPage.new
        organization.create_new_organization("test", "testDescription")

        organization.delete_organization("test")
      end
    end
  end
