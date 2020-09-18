require "rails_helper"

RSpec.describe AdminsController, type: :controller do
  let(:user) { create(:admin) }

  before do
    sign_in(user.email_authentication)
  end

  describe "#index" do
    context "user does not have permission to manage admins" do
      it "redirects the user" do
        get :index
        expect(response).to be_redirect
      end
    end

    context "user has permission to manage admins" do
      before { user.user_permissions.create(permission_slug: :manage_admins) }

      it "responds with ok" do
        get :index
        expect(response).to be_ok
      end

      it "populates a subset of filtered admins by search term" do
        admin1 = create(:admin, full_name: "Doctor Jack")
        _admin = create(:admin, full_name: "Jack")

        get :index, params: {search_query: "Doctor"}
        expect(assigns(:admins)).to match_array(admin1)
        expect(response).to be_successful
      end

      it "fetches no admins for search term with no matches" do
        create(:admin, full_name: "Doctor Jack")
        create(:admin, full_name: "Jack")

        get :index, params: {search_query: "Shephard"}
        expect(assigns(:admins)).to match_array([])
        expect(response).to be_successful
      end
    end
  end

  describe "#show" do
    let(:existing_admin) { create(:admin) }
    context "user does not have permission to manage admins" do
      it "redirects the user" do
        get :show, params: {id: existing_admin.id}

        expect(response).to be_redirect
      end
    end

    context "user has permission to manage admins" do
      before { user.user_permissions.create(permission_slug: :manage_admins) }
      it "respond with ok" do
        get :show, params: {id: existing_admin.id}

        expect(response).to be_ok
      end
    end
  end

  describe "#edit" do
    let(:existing_admin) { create(:admin) }
    context "user does not have permission to manage admins" do
      it "redirects the user" do
        get :edit, params: {id: existing_admin.id}

        expect(response).to be_redirect
      end
    end

    context "user has permission to manage admins" do
      before { user.user_permissions.create(permission_slug: :manage_admins) }
      it "response with ok" do
        get :edit, params: {id: existing_admin.id}

        expect(response).to be_ok
      end
    end
  end

  describe "#destroy" do
    let(:existing_admin) { create(:admin) }
    context "user does not have permission to manage admins" do
      it "redirects the user" do
        delete :destroy, params: {id: existing_admin.id}

        expect(response).to be_redirect
      end
    end

    context "user has permission to manage admins" do
      before { user.user_permissions.create(permission_slug: :manage_admins) }
      it "respond with ok" do
        delete :destroy, params: {id: existing_admin.id}

        expect(response).to be_redirect
      end
    end
  end

  describe "#update" do
    context "legacy permissions" do
      let(:organization) { create(:organization) }
      let(:facility_group) { create(:facility_group, organization: organization) }

      let(:full_name) { Faker::Name.name }
      let(:email) { Faker::Internet.email }
      let(:role) { "Test User Role" }

      let(:params) do
        {full_name: full_name,
         email: email,
         role: role,
         organization_id: organization.id}
      end

      let(:permission_params) do
        [{permission_slug: :manage_organizations},
          {permission_slug: :manage_facility_groups,
           resource_type: "Organization",
           resource_id: organization.id},
          {permission_slug: :manage_facilities,
           resource_type: "FacilityGroup",
           resource_id: facility_group.id}]
      end

      let(:existing_admin) { create(:admin, params) }

      context "user does not have permission to manage admins" do
        it "redirects the user" do
          put :update, params: params.merge(id: existing_admin.id)

          expect(response).to be_redirect
        end
      end

      context "user has permission to manage admins" do
        before { user.user_permissions.create(permission_slug: :manage_admins) }

        context "update params are valid" do
          it "allows updating user full name" do
            new_name = Faker::Name.name
            put :update, params: params.merge(id: existing_admin.id, full_name: new_name)

            existing_admin.reload

            expect(response).to be_ok
            expect(existing_admin.full_name).to eq(new_name)
          end

          it "allows updating user role" do
            new_role = "New user role"
            put :update, params: params.merge(id: existing_admin.id, role: new_role)

            existing_admin.reload

            expect(response).to be_ok
            expect(existing_admin.role).to eq(new_role)
          end

          it "does not allow updating user email" do
            new_email = Faker::Internet.email
            put :update, params: params.merge(id: existing_admin.id, email: new_email)

            existing_admin.reload

            expect(response).to be_ok
            expect(existing_admin.role).not_to eq(new_email)
          end

          it "updates user permissions" do
            put :update, params: params.merge(id: existing_admin.id, permissions: permission_params)

            existing_admin.reload
            expect(existing_admin.user_permissions.pluck(:permission_slug))
              .to match_array(permission_params.map { |p| p[:permission_slug].to_s })
          end
        end

        context "update params are invalid" do
          it "responds with bad request if full name is missing" do
            put :update, params: params.merge(id: existing_admin.id, full_name: nil)

            expect(response).to be_bad_request
            expect(JSON(response.body)).to eq("errors" => ["Full name can't be blank"])
          end

          it "responds with bad request if role is missing" do
            put :update, params: params.merge(id: existing_admin.id, role: nil)

            expect(response).to be_bad_request
            expect(JSON(response.body)).to eq("errors" => ["Role can't be blank"])
          end
        end
      end
    end

    context "new permissions" do
      let(:organization) { create(:organization) }
      let(:facility_group) { create(:facility_group, organization: organization) }
      let(:facilities) { create_list(:facility, 2, facility_group: facility_group) }
      let(:manager) { create(:admin, :manager, :with_access, resource: organization) }
      let(:power_user) { create(:admin, :power_user) }
      let(:full_name) { Faker::Name.name }
      let(:email) { Faker::Internet.email }
      let(:job_title) { "Title" }
      let(:params) {
        {
          full_name: full_name,
          email: email,
          role: job_title,
          access_level: :manager,
          organization_id: organization.id
        }
      }
      let(:admin_being_updated) { create(:admin, :with_access, params.merge(resource: facility_group)) }
      let(:selected_facility_ids) { facilities.map(&:id) }

      before(:each) do
        sign_in(manager.email_authentication)
        enable_flag(:new_permissions_system_aug_2020, manager)
      end

      after(:each) do
        disable_flag(:new_permissions_system_aug_2020, manager)
      end

      context "validate params" do
        let(:request_params) { params.merge(id: admin_being_updated.id, facilities: selected_facility_ids) }

        context "update params are valid" do
          it "responds with a 200" do
            put :update, params: request_params

            expect(response).to redirect_to(admins_url)
          end

          it "allows power users to upgrade admins to a power user without setting facilities" do
            enable_flag(:new_permissions_system_aug_2020, power_user)
            sign_in(power_user.email_authentication)

            put :update, params: request_params.merge(access_level: :power_user, facilities: nil)

            expect(response).to redirect_to(admins_url)
          end
        end

        context "update params are invalid" do
          [:full_name, :role].each do |param|
            it "responds with bad_request if #{param} is missing" do
              put :update, params: request_params.merge(param => nil)

              expect(response).to be_bad_request
            end
          end

          it "responds with bad_request if selected facilities are missing for non-power users" do
            put :update, params: request_params.merge(facilities: nil)

            expect(response).to be_bad_request
          end
        end
      end

      context "user can manage admins" do
        let(:request_params) { params.merge(id: admin_being_updated.id, facilities: selected_facility_ids) }

        it "updates attributes" do
          params =
            {
              full_name: Faker::Name.name,
              role: "New user title"
            }

          put :update, params: request_params.merge(params)

          admin_being_updated.reload

          expect(response).to redirect_to(admins_url)
          expect(admin_being_updated.full_name).to eq(params[:full_name])
          expect(admin_being_updated.role).to eq(params[:role])
        end

        it "updating email is disallowed" do
          new_email = Faker::Internet.email
          put :update, params: request_params.merge(email: new_email)

          admin_being_updated.reload

          expect(response).to redirect_to(admins_url)
          expect(admin_being_updated.email).not_to eq(new_email)
        end

        context "updating access level is restricted" do
          it "updating access level is allowed if power-user" do
            sign_out(manager.email_authentication)

            enable_flag(:new_permissions_system_aug_2020, power_user)
            sign_in(power_user.email_authentication)

            new_access_level = "viewer_all"
            put :update, params: request_params.merge(access_level: new_access_level)

            admin_being_updated.reload

            expect(response).to redirect_to(admins_url)
            expect(admin_being_updated.access_level).to eq(new_access_level)
          end

          it "updating access level is allowed if manager has organization access" do
            new_access_level = "viewer_all"
            put :update, params: request_params.merge(access_level: new_access_level)

            admin_being_updated.reload

            expect(response).to redirect_to(admins_url)
            expect(admin_being_updated.access_level).to eq(new_access_level)
          end

          it "disallow other admins from updating the access level" do
            manager.accesses.delete_all
            manager.accesses.create(resource: facility_group)

            new_access_level = "viewer_all"
            put :update, params: request_params.merge(access_level: new_access_level)

            admin_being_updated.reload

            expect(response).to redirect_to(root_path)
            expect(admin_being_updated.access_level).to_not eq(new_access_level)
          end
        end

        context "update accesses" do
          it "allows managers to update the accesses" do
            facility_group = create(:facility_group, organization: organization)
            facilities = create_list(:facility, 2, facility_group: facility_group)
            sign_in(manager.email_authentication)

            put :update, params: request_params.merge(facilities: facilities.map(&:id))

            admin_being_updated.reload

            expect(response).to redirect_to(admins_url)
            expect(admin_being_updated.accessible_facilities(:any)).to match_array(facilities)
          end

          it "allows power users to update the accesses" do
            facility_group = create(:facility_group, organization: organization)
            facilities = create_list(:facility, 2, facility_group: facility_group)
            enable_flag(:new_permissions_system_aug_2020, power_user)
            sign_in(power_user.email_authentication)

            put :update, params: request_params.merge(facilities: facilities.map(&:id))

            admin_being_updated.reload

            expect(response).to redirect_to(admins_url)
            expect(admin_being_updated.accessible_facilities(:any)).to match_array(facilities)
          end
        end
      end

      context "user cannot manage admins" do
        let(:request_params) { params.merge(id: admin_being_updated.id, facilities: selected_facility_ids) }

        it "disallows non-managers from updating access" do
          managers = %w[manager power_user]
          non_managers = User.access_levels.except(*managers).keys

          non_managers.each do |access_level|
            non_manager = create(:admin, access_level.to_sym, :with_access, resource: organization)
            enable_flag(:new_permissions_system_aug_2020, non_manager)
            sign_in(non_manager.email_authentication)

            put :update, params: request_params
            expect(response).to redirect_to(root_path)
          end
        end
      end
    end
  end

  describe "#access_tree" do
    let(:organization) { create(:organization) }
    let(:current_admin) {
      current_admin = create(:admin, :manager, organization: organization)
      current_admin.accesses.create!(resource: organization)
      current_admin
    }
    let(:existing_admin) {
      admin = create(:admin, :manager, organization: organization)
      admin.accesses.create!(resource: organization)
      admin
    }

    before do
      facility_group_1 = create(:facility_group, organization: organization)
      facility_group_2 = create(:facility_group, organization: organization)
      create(:facility, facility_group: facility_group_1)
      create(:facility, facility_group: facility_group_2)

      enable_flag(:new_permissions_system_aug_2020, current_admin)
      sign_in(current_admin.email_authentication)
    end

    after do
      disable_flag(:new_permissions_system_aug_2020, current_admin)
    end

    it "pulls up the tree for the admin when the page is show" do
      access_tree = AdminAccessPresenter.new(existing_admin).visible_access_tree

      expected_locals = {
        tree: access_tree[:data],
        root: :facility_group,
        user_being_edited: nil,
        tree_depth: 0,
        page: :show
      }

      expect(controller).to receive(:render).with({
        partial: access_tree[:render_partial],
        locals: expected_locals
      })

      get :access_tree, params: {id: existing_admin.id, page: :show}, xhr: true
    end

    it "pulls up the tree for the current admin when the page is new" do
      access_tree = AdminAccessPresenter.new(current_admin).visible_access_tree

      expected_locals = {
        tree: access_tree[:data],
        root: :facility_group,
        user_being_edited: nil,
        tree_depth: 0,
        page: :new
      }

      expect(controller).to receive(:render).with({
        partial: access_tree[:render_partial],
        locals: expected_locals
      })

      get :access_tree, params: {id: current_admin.id, page: :new}, xhr: true
    end

    it "sets the admin as the user_being_edited when the page is edit" do
      access_tree = AdminAccessPresenter.new(current_admin).visible_access_tree

      expected_locals = {
        tree: access_tree[:data],
        root: :facility_group,
        user_being_edited: AdminAccessPresenter.new(existing_admin),
        tree_depth: 0,
        page: :edit
      }

      expect(controller).to receive(:render).with({
        partial: access_tree[:render_partial],
        locals: expected_locals
      })

      get :access_tree, params: {id: existing_admin.id, page: :edit}, xhr: true
    end

    it "returns a 404 if the page is invalid" do
      get :access_tree, params: {id: existing_admin.id, page: :garble}

      expect(response).to be_not_found
    end
  end
end
