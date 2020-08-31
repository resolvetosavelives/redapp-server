require "rails_helper"

RSpec.describe UserAccess, type: :model do
  let(:viewer) { UserAccess.new(create(:admin, :viewer)) }
  let(:manager) { UserAccess.new(create(:admin, :manager)) }

  describe "#can?" do
    context "organizations" do
      let!(:organization_1) { create(:organization) }
      let!(:organization_2) { create(:organization) }
      let!(:organization_3) { create(:organization) }

      context "view action" do
        it "allows manager to view" do
          create(:access, user: manager.user, resource: organization_1)

          expect(manager.can?(:view, :organization, organization_1)).to be true
          expect(manager.can?(:view, :organization, organization_2)).to be false
          expect(manager.can?(:view, :organization, organization_3)).to be false
          expect(manager.can?(:view, :organization)).to be true
        end

        it "allows viewer to view" do
          create(:access, user: viewer.user, resource: organization_3)

          expect(viewer.can?(:view, :organization, organization_1)).to be false
          expect(viewer.can?(:view, :organization, organization_2)).to be false
          expect(viewer.can?(:view, :organization, organization_3)).to be true
          expect(viewer.can?(:view, :organization)).to be true
        end
      end

      context "manage action" do
        it "allows manager to manage" do
          create(:access, user: manager.user, resource: organization_1)

          expect(manager.can?(:manage, :organization, organization_1)).to be true
          expect(manager.can?(:manage, :organization, organization_2)).to be false
          expect(manager.can?(:manage, :organization, organization_3)).to be false
          expect(manager.can?(:manage, :organization)).to be true
        end

        it "allows viewer to manage" do
          create(:access, user: viewer.user, resource: organization_3)

          expect(viewer.can?(:manage, :organization, organization_1)).to be false
          expect(viewer.can?(:manage, :organization, organization_2)).to be false
          expect(viewer.can?(:manage, :organization, organization_3)).to be false
          expect(viewer.can?(:manage, :organization)).to be false
        end
      end
    end

    context "facility_groups" do
      let!(:facility_group_1) { create(:facility_group) }
      let!(:facility_group_2) { create(:facility_group) }
      let!(:facility_group_3) { create(:facility_group) }

      context "view action" do
        it "allows manager to view" do
          create(:access, user: manager.user, resource: facility_group_1)

          expect(manager.can?(:view, :facility_group, facility_group_1)).to be true
          expect(manager.can?(:view, :facility_group, facility_group_2)).to be false
          expect(manager.can?(:view, :facility_group, facility_group_3)).to be false
          expect(manager.can?(:view, :facility_group)).to be true
        end

        it "allows viewer to view" do
          create(:access, user: viewer.user, resource: facility_group_3)

          expect(viewer.can?(:view, :facility_group, facility_group_1)).to be false
          expect(viewer.can?(:view, :facility_group, facility_group_2)).to be false
          expect(viewer.can?(:view, :facility_group, facility_group_3)).to be true
          expect(viewer.can?(:view, :facility_group)).to be true
        end
      end

      context "manage action" do
        it "allows manager to manage" do
          create(:access, user: manager.user, resource: facility_group_1)

          expect(manager.can?(:manage, :facility_group, facility_group_1)).to be true
          expect(manager.can?(:manage, :facility_group, facility_group_2)).to be false
          expect(manager.can?(:manage, :facility_group, facility_group_3)).to be false
          expect(manager.can?(:manage, :facility_group)).to be true
        end

        it "allows viewer to manage" do
          create(:access, user: viewer.user, resource: facility_group_3)

          expect(viewer.can?(:manage, :facility_group, facility_group_1)).to be false
          expect(viewer.can?(:manage, :facility_group, facility_group_2)).to be false
          expect(viewer.can?(:manage, :facility_group, facility_group_3)).to be false
          expect(viewer.can?(:manage, :facility_group)).to be false
        end
      end

      context "when org-level access" do
        let!(:organization_1) { create(:organization) }
        let!(:facility_group_1) { create(:facility_group, organization: organization_1) }
        let!(:facility_group_2) { create(:facility_group) }
        let!(:facility_group_3) { create(:facility_group) }

        it "allows manager to view" do
          create(:access, user: manager.user, resource: organization_1)
          create(:access, user: manager.user, resource: facility_group_2)

          expect(manager.can?(:view, :facility_group, facility_group_1)).to be true
          expect(manager.can?(:view, :facility_group, facility_group_2)).to be true
          expect(manager.can?(:view, :facility_group, facility_group_3)).to be false
          expect(manager.can?(:view, :facility_group)).to be true
        end

        it "allows viewer to view" do
          create(:access, user: viewer.user, resource: organization_1)
          create(:access, user: viewer.user, resource: facility_group_2)

          expect(viewer.can?(:view, :facility_group, facility_group_1)).to be true
          expect(viewer.can?(:view, :facility_group, facility_group_2)).to be true
          expect(viewer.can?(:view, :facility_group, facility_group_3)).to be false
          expect(viewer.can?(:view, :facility_group)).to be true
        end

        it "does not allow viewer to manage" do
          create(:access, user: viewer.user, resource: organization_1)
          create(:access, user: viewer.user, resource: facility_group_2)

          expect(viewer.can?(:manage, :facility_group, facility_group_1)).to be false
          expect(viewer.can?(:manage, :facility_group, facility_group_2)).to be false
          expect(viewer.can?(:manage, :facility_group, facility_group_3)).to be false
          expect(viewer.can?(:manage, :facility_group)).to be false
        end

        it "allows manager to manage" do
          create(:access, user: manager.user, resource: organization_1)
          create(:access, user: manager.user, resource: facility_group_2)

          expect(manager.can?(:manage, :facility_group, facility_group_1)).to be true
          expect(manager.can?(:manage, :facility_group, facility_group_2)).to be true
          expect(manager.can?(:manage, :facility_group, facility_group_3)).to be false
          expect(manager.can?(:manage, :facility_group)).to be true
        end
      end
    end

    context "facility" do
      let!(:facility_1) { create(:facility) }
      let!(:facility_2) { create(:facility) }
      let!(:facility_3) { create(:facility) }

      context "view action" do
        it "allows manager to view" do
          create(:access, user: manager.user, resource: facility_1)

          expect(manager.can?(:view, :facility, facility_1)).to be true
          expect(manager.can?(:view, :facility, facility_2)).to be false
          expect(manager.can?(:view, :facility, facility_3)).to be false
          expect(manager.can?(:view, :facility)).to be true
        end

        it "allows viewer to view" do
          create(:access, user: viewer.user, resource: facility_3)

          expect(viewer.can?(:view, :facility, facility_1)).to be false
          expect(viewer.can?(:view, :facility, facility_2)).to be false
          expect(viewer.can?(:view, :facility, facility_3)).to be true
          expect(viewer.can?(:view, :facility)).to be true
        end
      end

      context "manage action" do
        it "allows manager to manage" do
          create(:access, user: manager.user, resource: facility_1)

          expect(manager.can?(:manage, :facility, facility_1)).to be true
          expect(manager.can?(:manage, :facility, facility_2)).to be false
          expect(manager.can?(:manage, :facility, facility_3)).to be false
          expect(manager.can?(:manage, :facility)).to be true
        end

        it "allows viewer to manage" do
          create(:access, user: viewer.user, resource: facility_3)

          expect(viewer.can?(:manage, :facility, facility_1)).to be false
          expect(viewer.can?(:manage, :facility, facility_2)).to be false
          expect(viewer.can?(:manage, :facility, facility_3)).to be false
          expect(viewer.can?(:manage, :facility)).to be false
        end
      end

      context "when facility-group-level access" do
        let!(:facility_group_1) { create(:facility_group) }
        let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
        let!(:facility_2) { create(:facility) }
        let!(:facility_3) { create(:facility) }

        it "allows manager to view" do
          create(:access, user: manager.user, resource: facility_group_1)
          create(:access, user: manager.user, resource: facility_2)

          expect(manager.can?(:view, :facility, facility_1)).to be true
          expect(manager.can?(:view, :facility, facility_2)).to be true
          expect(manager.can?(:view, :facility, facility_3)).to be false
          expect(manager.can?(:view, :facility)).to be true
        end

        it "allows viewer to view" do
          create(:access, user: viewer.user, resource: facility_group_1)
          create(:access, user: viewer.user, resource: facility_2)

          expect(viewer.can?(:view, :facility, facility_1)).to be true
          expect(viewer.can?(:view, :facility, facility_2)).to be true
          expect(viewer.can?(:view, :facility, facility_3)).to be false
          expect(viewer.can?(:view, :facility)).to be true
        end

        it "does not allow viewer to manage" do
          create(:access, user: viewer.user, resource: facility_group_1)
          create(:access, user: viewer.user, resource: facility_2)

          expect(viewer.can?(:manage, :facility, facility_1)).to be false
          expect(viewer.can?(:manage, :facility, facility_2)).to be false
          expect(viewer.can?(:manage, :facility, facility_3)).to be false
          expect(viewer.can?(:manage, :facility)).to be false
        end

        it "allows manager to manage" do
          create(:access, user: manager.user, resource: facility_group_1)
          create(:access, user: manager.user, resource: facility_2)

          expect(manager.can?(:manage, :facility, facility_1)).to be true
          expect(manager.can?(:manage, :facility, facility_2)).to be true
          expect(manager.can?(:manage, :facility, facility_3)).to be false
          expect(manager.can?(:manage, :facility)).to be true
        end
      end

      context "when org-level access" do
        let!(:organization_1) { create(:organization) }
        let!(:facility_group_1) { create(:facility_group, organization: organization_1) }
        let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
        let!(:facility_2) { create(:facility) }
        let!(:facility_3) { create(:facility) }

        it "allows manager to view" do
          create(:access, user: manager.user, resource: organization_1)
          create(:access, user: manager.user, resource: facility_2)

          expect(manager.can?(:view, :facility, facility_1)).to be true
          expect(manager.can?(:view, :facility, facility_2)).to be true
          expect(manager.can?(:view, :facility, facility_3)).to be false
          expect(manager.can?(:view, :facility)).to be true
        end

        it "allows viewer to view" do
          create(:access, user: viewer.user, resource: organization_1)
          create(:access, user: viewer.user, resource: facility_2)

          expect(viewer.can?(:view, :facility, facility_1)).to be true
          expect(viewer.can?(:view, :facility, facility_2)).to be true
          expect(viewer.can?(:view, :facility, facility_3)).to be false
          expect(viewer.can?(:view, :facility)).to be true
        end

        it "does not allow viewer to manage" do
          create(:access, user: viewer.user, resource: organization_1)
          create(:access, user: viewer.user, resource: facility_2)

          expect(viewer.can?(:manage, :facility, facility_1)).to be false
          expect(viewer.can?(:manage, :facility, facility_2)).to be false
          expect(viewer.can?(:manage, :facility, facility_3)).to be false
          expect(viewer.can?(:manage, :facility)).to be false
        end

        it "allows manager to manage" do
          create(:access, user: manager.user, resource: organization_1)
          create(:access, user: manager.user, resource: facility_2)

          expect(manager.can?(:manage, :facility, facility_1)).to be true
          expect(manager.can?(:manage, :facility, facility_2)).to be true
          expect(manager.can?(:manage, :facility, facility_3)).to be false
          expect(manager.can?(:manage, :facility)).to be true
        end
      end
    end
  end

  describe "#accessible_organizations" do
    let!(:organization_1) { create(:organization) }
    let!(:organization_2) { create(:organization) }
    let!(:organization_3) { create(:organization) }

    it "returns all organizations for power users" do
      admin = create(:admin, :power_user)

      expect(admin.accessible_organizations(:any_action)).to match_array(Organization.all)
    end

    context "for a direct organization-level access" do
      let!(:viewer_access) { create(:access, user: viewer.user, resource: organization_2) }
      let!(:manager_access) { create(:access, user: manager.user, resource: organization_1) }

      context "view action" do
        it "returns all organizations the manager can view" do
          expect(manager.accessible_organizations(:view)).to contain_exactly(organization_1)
          expect(manager.accessible_organizations(:view)).not_to contain_exactly(organization_2)
        end

        it "returns all organizations the viewer can view" do
          expect(viewer.accessible_organizations(:view)).to contain_exactly(organization_2)
          expect(viewer.accessible_organizations(:view)).not_to contain_exactly(organization_1)
        end
      end

      context "manage action" do
        it "returns all organizations the manager can manage" do
          expect(manager.accessible_organizations(:manage)).to contain_exactly(organization_1)
          expect(manager.accessible_organizations(:manage)).not_to contain_exactly(organization_2)
        end

        it "returns all organizations the viewer can manage" do
          expect(viewer.accessible_organizations(:manage)).to be_empty
        end
      end
    end

    context "for a lower-level access than organization" do
      context "facility_group access" do
        let!(:viewer_access) { create(:access, user: viewer.user, resource: create(:facility_group)) }
        let!(:manager_access) { create(:access, user: manager.user, resource: create(:facility_group)) }

        it "returns no organizations" do
          expect(viewer.accessible_organizations(:view)).to be_empty
          expect(manager.accessible_organizations(:view)).to be_empty
          expect(viewer.accessible_organizations(:manage)).to be_empty
          expect(manager.accessible_organizations(:manage)).to be_empty
        end
      end

      context "facility access" do
        let!(:viewer_access) { create(:access, user: viewer.user, resource: create(:facility)) }
        let!(:manager_access) { create(:access, user: manager.user, resource: create(:facility)) }

        it "returns no organizations" do
          expect(viewer.accessible_organizations(:view)).to be_empty
          expect(manager.accessible_organizations(:view)).to be_empty
          expect(viewer.accessible_organizations(:manage)).to be_empty
          expect(manager.accessible_organizations(:manage)).to be_empty
        end
      end
    end
  end

  describe "#accessible_facility_groups" do
    it "returns all facility_groups for power users" do
      admin = create(:admin, :power_user)
      create_list(:facility_group, 5)

      expect(admin.accessible_facility_groups(:any_action)).to match_array(FacilityGroup.all)
    end

    context "for a direct facility-group-level access" do
      let!(:facility_group_1) { create(:facility_group) }
      let!(:facility_group_2) { create(:facility_group) }
      let!(:facility_group_3) { create(:facility_group) }
      let!(:manager_access) { create(:access, user: manager.user, resource: facility_group_1) }
      let!(:viewer_access) { create(:access, user: viewer.user, resource: facility_group_2) }

      context "view action" do
        it "returns all facility_groups the manager can view" do
          expect(manager.accessible_facility_groups(:view)).to contain_exactly(facility_group_1)
          expect(manager.accessible_facility_groups(:view)).not_to contain_exactly(facility_group_2, facility_group_3)
        end

        it "returns all facility_groups the viewer can view" do
          expect(viewer.accessible_facility_groups(:view)).to contain_exactly(facility_group_2)
          expect(viewer.accessible_facility_groups(:view)).not_to contain_exactly(facility_group_1, facility_group_3)
        end
      end

      context "manage action" do
        it "returns all facility_groups the manager can manage" do
          expect(manager.accessible_facility_groups(:manage)).to contain_exactly(facility_group_1)
          expect(manager.accessible_facility_groups(:manage)).not_to contain_exactly(facility_group_2, facility_group_3)
        end

        it "returns all facility_groups the viewer can manage" do
          expect(viewer.accessible_facility_groups(:manage)).to be_empty
        end
      end
    end

    context "for a higher-level organization access" do
      let!(:organization_1) { create(:organization) }
      let!(:organization_2) { create(:organization) }
      let!(:organization_3) { create(:organization) }

      let!(:facility_group_1) { create(:facility_group, organization: organization_1) }
      let!(:facility_group_2) { create(:facility_group, organization: organization_2) }
      let!(:facility_group_3) { create(:facility_group, organization: organization_3) }
      let!(:facility_group_4) { create(:facility_group, organization: organization_3) }

      let!(:org_manager_access) { create(:access, user: manager.user, resource: organization_1) }
      let!(:fg_manager_access) { create(:access, user: manager.user, resource: facility_group_3) }

      let!(:org_viewer_access) { create(:access, user: viewer.user, resource: organization_2) }
      let!(:fg_viewer_access) { create(:access, user: viewer.user, resource: facility_group_4) }

      context "view action" do
        it "returns all facilities the manager can view" do
          expect(manager.accessible_facility_groups(:view)).to contain_exactly(facility_group_1, facility_group_3)
          expect(manager.accessible_facility_groups(:view)).not_to contain_exactly(facility_group_2, facility_group_4)
        end

        it "returns all facility_groups the viewer can view" do
          expect(viewer.accessible_facility_groups(:view)).to contain_exactly(facility_group_2, facility_group_4)
          expect(viewer.accessible_facility_groups(:view)).not_to contain_exactly(facility_group_1, facility_group_3)
        end
      end

      context "manage action" do
        it "returns all facility_groups the manager can manage" do
          expect(manager.accessible_facility_groups(:manage)).to contain_exactly(facility_group_1, facility_group_3)
          expect(manager.accessible_facility_groups(:manage)).not_to contain_exactly(facility_group_2, facility_group_4)
        end

        it "returns all facility_groups the viewer can manage" do
          expect(viewer.accessible_facility_groups(:manage)).to be_empty
        end
      end
    end

    context "for a lower-level access than facility_group or organization" do
      context "facility access" do
        let!(:viewer_access) { create(:access, user: viewer.user, resource: create(:facility)) }
        let!(:manager_access) { create(:access, user: manager.user, resource: create(:facility)) }

        it "returns no facility_groups" do
          expect(viewer.accessible_facility_groups(:view)).to be_empty
          expect(manager.accessible_facility_groups(:view)).to be_empty
          expect(viewer.accessible_facility_groups(:manage)).to be_empty
          expect(manager.accessible_facility_groups(:manage)).to be_empty
        end
      end
    end
  end

  describe "#accessible_facilities" do
    it "returns all facilities for power users" do
      admin = create(:admin, :power_user)
      create_list(:facility, 5)

      expect(admin.accessible_facilities(:any_action)).to match_array(Facility.all)
    end

    context "for a direct facility-level access" do
      let!(:facility_1) { create(:facility) }
      let!(:facility_2) { create(:facility) }
      let!(:facility_3) { create(:facility) }
      let!(:manager_access) { create(:access, user: manager.user, resource: facility_1) }
      let!(:viewer_access) { create(:access, user: viewer.user, resource: facility_2) }

      context "view action" do
        it "returns all facilities the manager can view" do
          expect(manager.accessible_facilities(:view)).to contain_exactly(facility_1)
          expect(manager.accessible_facilities(:view)).not_to contain_exactly(facility_2, facility_3)
        end

        it "returns all facilities the viewer can view" do
          expect(viewer.accessible_facilities(:view)).to contain_exactly(facility_2)
          expect(viewer.accessible_facilities(:view)).not_to contain_exactly(facility_1, facility_3)
        end
      end

      context "manage action" do
        it "returns all facilities the manager can manage" do
          expect(manager.accessible_facilities(:manage)).to contain_exactly(facility_1)
          expect(manager.accessible_facilities(:manage)).not_to contain_exactly(facility_2, facility_3)
        end

        it "returns all facilities the viewer can manage" do
          expect(viewer.accessible_facilities(:manage)).to be_empty
        end
      end
    end

    context "for a higher-level facility_group access" do
      let!(:facility_group_1) { create(:facility_group) }
      let!(:facility_group_2) { create(:facility_group) }
      let!(:facility_group_3) { create(:facility_group) }

      let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
      let!(:facility_2) { create(:facility, facility_group: facility_group_2) }
      let!(:facility_3) { create(:facility, facility_group: facility_group_3) }
      let!(:facility_4) { create(:facility) }
      let!(:facility_5) { create(:facility) }
      let!(:facility_6) { create(:facility) }

      let!(:manager_access) { create(:access, user: manager.user, resource: facility_group_1) }
      let!(:facility_manager_access) { create(:access, user: manager.user, resource: facility_4) }

      let!(:viewer_access) { create(:access, user: viewer.user, resource: facility_group_2) }
      let!(:facility_viewer_access) { create(:access, user: viewer.user, resource: facility_5) }

      context "view action" do
        it "returns all facilities the manager can view" do
          expect(manager.accessible_facilities(:view)).to contain_exactly(facility_1, facility_4)
          expect(manager.accessible_facilities(:view)).not_to contain_exactly(facility_2, facility_3, facility_5, facility_6)
        end

        it "returns all facilities the viewer can view" do
          expect(viewer.accessible_facilities(:view)).to contain_exactly(facility_2, facility_5)
          expect(viewer.accessible_facilities(:view)).not_to contain_exactly(facility_1, facility_3, facility_4, facility_6)
        end
      end

      context "manage action" do
        it "returns all facilities the manager can manage" do
          expect(manager.accessible_facilities(:manage)).to contain_exactly(facility_1, facility_4)
          expect(manager.accessible_facilities(:manage)).not_to contain_exactly(facility_2, facility_3, facility_5, facility_6)
        end

        it "returns all facilities the viewer can manage" do
          expect(viewer.accessible_facilities(:manage)).to be_empty
        end
      end
    end

    context "for a higher-level organization access" do
      let!(:organization_1) { create(:organization) }
      let!(:organization_2) { create(:organization) }
      let!(:organization_3) { create(:organization) }

      let!(:facility_group_1) { create(:facility_group, organization: organization_1) }
      let!(:facility_group_2) { create(:facility_group, organization: organization_2) }
      let!(:facility_group_3) { create(:facility_group, organization: organization_3) }
      let!(:facility_group_4) { create(:facility_group, organization: organization_3) }

      let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
      let!(:facility_2) { create(:facility, facility_group: facility_group_2) }
      let!(:facility_3) { create(:facility, facility_group: facility_group_3) }
      let!(:facility_4) { create(:facility, facility_group: facility_group_4) }
      let!(:facility_5) { create(:facility) }
      let!(:facility_6) { create(:facility) }

      let!(:org_manager_access) { create(:access, user: manager.user, resource: organization_1) }
      let!(:fg_manager_access) { create(:access, user: manager.user, resource: facility_group_3) }
      let!(:facility_manager_access) { create(:access, user: manager.user, resource: facility_5) }

      let!(:viewer_access) { create(:access, user: viewer.user, resource: organization_2) }
      let!(:facility_viewer_access) { create(:access, user: viewer.user, resource: facility_6) }

      context "view action" do
        it "returns all facilities the manager can view" do
          expect(manager.accessible_facilities(:view)).to contain_exactly(facility_1, facility_3, facility_5)
          expect(manager.accessible_facilities(:view)).not_to contain_exactly(facility_2, facility_4, facility_6)
        end

        it "returns all facilities the viewer can view" do
          expect(viewer.accessible_facilities(:view)).to contain_exactly(facility_2, facility_6)
          expect(viewer.accessible_facilities(:view)).not_to contain_exactly(facility_1, facility_3, facility_4, facility_5)
        end
      end

      context "manage action" do
        it "returns all facilities the manager can manage" do
          expect(manager.accessible_facilities(:manage)).to contain_exactly(facility_1, facility_3, facility_5)
          expect(manager.accessible_facilities(:manage)).not_to contain_exactly(facility_2, facility_4, facility_6)
        end

        it "returns all facilities the viewer can manage" do
          expect(viewer.accessible_facilities(:manage)).to be_empty
        end
      end
    end
  end

  describe "#grant_access" do
    let!(:organization_1) { create(:organization) }
    let!(:organization_2) { create(:organization) }
    let!(:facility_group_1) { create(:facility_group, organization: organization_1) }
    let!(:facility_group_2) { create(:facility_group, organization: organization_2) }
    let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
    let!(:facility_2) { create(:facility, facility_group: facility_group_1) }
    let!(:facility_3) { create(:facility, facility_group: facility_group_2) }
    let!(:facility_4) { create(:facility) }
    let!(:viewer_access) {
      create(:access, user: viewer.user, resource: organization_1)
    }
    let!(:manager_access) {
      [create(:access, user: manager.user, resource: organization_1),
        create(:access, user: manager.user, resource: facility_group_2),
        create(:access, user: manager.user, resource: facility_4)]
    }

    it "raises an error if the access level of the new user is not grantable by the current" do
      new_user = create(:admin, :manager)

      expect {
        viewer.grant_access(new_user, [facility_1.id, facility_2.id])
      }.to raise_error(UserAccess::NotAuthorizedError)
    end

    it "raises an error if the user could not provide any access" do
      new_user = create(:admin, :viewer)

      expect {
        manager.grant_access(new_user, [create(:facility).id])
      }.to raise_error(UserAccess::NotAuthorizedError)
    end

    it "only grants access to the selected facilities" do
      new_user = create(:admin, :viewer)

      manager.grant_access(new_user, [facility_1.id, facility_2.id])

      expect(new_user.reload.accessible_facilities(:view)).to contain_exactly(facility_1, facility_2)
    end

    it "returns nothing if no facilities are selected" do
      new_user = create(:admin, :viewer)

      expect(manager.grant_access(new_user, [])).to be_nil
    end

    context "promote access" do
      it "promotes to FacilityGroup access" do
        new_user = create(:admin, :viewer)

        manager.grant_access(new_user, [facility_3.id])
        expected_access_resources = %w[FacilityGroup]

        expect(new_user.reload.accesses.map(&:resource_type)).to match_array(expected_access_resources)
      end

      it "promotes to Organization access" do
        new_user = create(:admin, :manager)

        manager.grant_access(new_user, [facility_1.id, facility_2.id])
        expected_access_resources = %w[Organization]

        expect(new_user.reload.accesses.map(&:resource_type)).to match_array(expected_access_resources)
      end

      it "gives access to individual facilities that cannot be promoted" do
        new_user = create(:admin, :manager)

        manager.grant_access(new_user, [facility_1.id, facility_2.id, facility_4.id])
        expected_access_resources = %w[Organization Facility]

        expect(new_user.reload.accesses.map(&:resource_type)).to match_array(expected_access_resources)
      end
    end

    context "allows editing accesses" do
      it "removes access" do
        new_user = create(:admin, :manager)

        manager.grant_access(new_user, [facility_1.id, facility_2.id, facility_4.id])
        expected_access_resources = %w[Organization Facility]

        expect(new_user.reload.accesses.map(&:resource_type)).to match_array(expected_access_resources)

        manager.grant_access(new_user, [facility_1.id, facility_2.id])
        expected_access_resources = %w[Organization]

        expect(new_user.reload.accesses.map(&:resource_type)).to match_array(expected_access_resources)
      end

      it "adds new access" do
        new_user = create(:admin, :manager)

        manager.grant_access(new_user, [facility_1.id, facility_2.id])
        expected_access_resources = %w[Organization]

        expect(new_user.reload.accesses.map(&:resource_type)).to match_array(expected_access_resources)

        manager.grant_access(new_user, [facility_1.id, facility_2.id, facility_4.id])
        expected_access_resources = %w[Organization Facility]

        expect(new_user.reload.accesses.map(&:resource_type)).to match_array(expected_access_resources)
      end
    end
  end

  describe "#access_tree" do
    let!(:organization_1) { create(:organization) }
    let!(:organization_2) { create(:organization) }
    let!(:organization_3) { create(:organization) }
    let!(:facility_group_1) { create(:facility_group, organization: organization_1) }
    let!(:facility_group_2) { create(:facility_group, organization: organization_2) }
    let!(:facility_group_3) { create(:facility_group, organization: organization_3) }
    let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
    let!(:facility_2) { create(:facility, facility_group: facility_group_1) }
    let!(:facility_3) { create(:facility, facility_group: facility_group_2) }
    let!(:facility_4) { create(:facility, facility_group: facility_group_3) }
    let!(:viewer_access) {
      create(:access, user: viewer.user, resource: organization_1)
    }
    let!(:manager_access) {
      create(:access, user: manager.user, resource: organization_1)
      create(:access, user: manager.user, resource: facility_3)
    }

    context "render a nested data structure" do
      it "only allows the direct parent or ancestors to be in the tree" do
        expected_access_tree = {
          organizations: {
            organization_1 => {
              can_access: true,
              total_facility_groups: 1,

              facility_groups: {
                facility_group_1 => {
                  can_access: true,
                  total_facilities: 2,

                  facilities: {
                    facility_1 => {
                      can_access: true
                    },

                    facility_2 => {
                      can_access: true
                    }
                  }
                }
              }
            }
          }
        }

        expect(viewer.access_tree(:view)).to eq(expected_access_tree)
        expect(viewer.access_tree(:manage)).to eq(organizations: {})
      end

      it "marks the direct parents or ancestors as inaccessible if the access is partial" do
        expected_access_tree = {
          organizations: {
            organization_1 => {
              can_access: true,
              total_facility_groups: 1,

              facility_groups: {
                facility_group_1 => {
                  can_access: true,
                  total_facilities: 2,

                  facilities: {
                    facility_1 => {
                      can_access: true
                    },

                    facility_2 => {
                      can_access: true
                    }
                  }
                }
              }
            },

            organization_2 => {
              can_access: false,
              total_facility_groups: 1,

              facility_groups: {
                facility_group_2 => {
                  can_access: false,
                  total_facilities: 1,

                  facilities: {
                    facility_3 => {
                      can_access: true
                    }
                  }
                }
              }
            }
          }
        }

        expect(manager.access_tree(:view)).to eq(expected_access_tree)
        expect(manager.access_tree(:manage)).to eq(expected_access_tree)
      end
    end
  end

  describe "#permitted_access_levels" do
    specify do
      power_user = create(:admin, :power_user)
      expect(power_user.permitted_access_levels).to match_array(UserAccess::LEVELS.keys)
    end

    specify do
      manager = create(:admin, :manager)
      expect(manager.permitted_access_levels).to match_array([:manager, :viewer])
    end

    specify do
      viewer = create(:admin, :viewer)
      expect(viewer.permitted_access_levels).to match_array([])
    end
  end
end
