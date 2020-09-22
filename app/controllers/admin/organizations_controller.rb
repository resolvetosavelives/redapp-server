class Admin::OrganizationsController < AdminController
  before_action :set_organization, only: [:edit, :update, :destroy]

  skip_after_action :verify_authorized, if: -> { current_admin.permissions_v2_enabled? }
  skip_after_action :verify_policy_scoped, if: -> { current_admin.permissions_v2_enabled? }
  after_action :verify_authorization_attempted, if: -> { current_admin.permissions_v2_enabled? }

  def index
    if current_admin.permissions_v2_enabled?
      authorize_v2 { current_admin.accessible_organizations(:manage).any? }
      @organizations = current_admin.accessible_organizations(:manage).order(:name)
    else
      authorize([:manage, Organization])
      @organizations = policy_scope([:manage, Organization]).order(:name)
    end
  end

  def new
    if current_admin.permissions_v2_enabled?
      authorize_v2 { current_admin.power_user? }
      @organization = Organization.new
    else
      @organization = Organization.new
      authorize([:manage, @organization])
    end
  end

  def edit
  end

  def create
    if current_admin.permissions_v2_enabled?
      authorize_v2 { current_admin.power_user? }
      @organization = Organization.new(organization_params)
    else
      @organization = Organization.new(organization_params)
      authorize([:manage, @organization])
    end

    if @organization.save
      redirect_to admin_organizations_url, notice: "Organization was successfully created."
    else
      render :new
    end
  end

  def update
    if @organization.update(organization_params)
      redirect_to admin_organizations_url, notice: "Organization was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    if @organization.discardable?
      @organization.discard
      redirect_to admin_organizations_url, notice: "Organization was successfully deleted."
    else
      redirect_to admin_facilities_url, notice: "Organization cannot be deleted, please delete Facility Groups and try again."
    end
  end

  private

  def set_organization
    if current_admin.permissions_v2_enabled?
      @organization = authorize_v2 { current_admin.accessible_organizations(:manage).friendly.find(params[:id]) }
    else
      @organization = Organization.friendly.find(params[:id])
      authorize([:manage, @organization])
    end
  end

  def organization_params
    params.require(:organization).permit(
      :name,
      :description
    )
  end
end
