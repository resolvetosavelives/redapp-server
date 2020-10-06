class OrganizationsController < AdminController
  include Pagination

  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  after_action :verify_authorization_attempted

  def index
    @accessible_facilities = current_admin.accessible_facilities(:view_reports)
    authorize_v2 { @accessible_facilities.any? }

    users = current_admin.accessible_users(:manage)

    @users_requesting_approval = users
      .requested_sync_approval
      .order(updated_at: :desc)

    @users_requesting_approval = paginate(users
                                            .requested_sync_approval
                                            .order(updated_at: :desc))

<<<<<<< HEAD
    @organizations =
      if current_admin.permissions_v2_enabled?
        org_ids = @accessible_facilities.includes(facility_group: :organization).flat_map(&:organization_id)
        Organization.where(id: org_ids).order(:name)
      else
        policy_scope([:cohort_report, Organization]).order(:name)
      end
=======
    @organizations = @accessible_facilities
      .includes(facility_group: :organization)
      .flat_map(&:organization)
      .uniq
      .compact
      .sort_by(&:name)
>>>>>>> origin/master
  end
end
