class AdminsController < AdminController
  include Pagination
  include SearchHelper

  before_action :set_admin, only: [:show, :edit, :update, :destroy], unless: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  before_action :🆕set_admin, only: [:show, :edit, :update, :access_tree], if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  before_action :verify_params, only: [:update], unless: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  before_action :🆕verify_params, only: [:update], if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  after_action :verify_policy_scoped, only: :index

  skip_after_action :verify_authorized, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  skip_after_action :verify_policy_scoped, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }

  def index
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      admins = current_admin.accessible_admins(:manage)
      authorize1 { admins.any? }

      @admins =
        if searching?
          paginate(admins.search_by_name_or_email(search_query))
        else
          paginate(admins.order("email_authentications.email"))
        end
    else
      authorize([:manage, :admin, User])
      admins = policy_scope([:manage, :admin, User])

      @admins =
        if searching?
          paginate(admins.search_by_name_or_email(search_query))
        else
          paginate(admins.order("email_authentications.email"))
        end
    end
  end

  def access_tree
    admin = access_tree_for_page.eql?(:show) ? @admin : current_admin
    user_being_edited = access_tree_for_page.eql?(:edit) ? @admin : nil

    access_tree = admin.visible_access_tree

    render partial: access_tree[:render_partial], locals: {
      tree: access_tree[:data],
      root: access_tree[:root],
      user_being_edited: user_being_edited,
      tree_depth: 0,
      page: access_tree_for_page,
    }
  end

  def show
  end

  def edit
    unless Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      authorize([:manage, :admin, current_admin])
    end
  end

  def update
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      User.transaction do
        @admin.update!(user_params)
        current_admin.grant_access(@admin, selected_facilities)
      end

      redirect_to admins_url, notice: "Admin was successfully updated."
    else
      User.transaction do
        @admin.update!(user_params)
        next unless permission_params.present?

        @admin.user_permissions.delete_all
        permission_params.each do |attributes|
          @admin.user_permissions.create!(attributes.permit(
            :permission_slug,
            :resource_id,
            :resource_type
          ))
        end
      end

      render json: {}, status: :ok
    end
  end

  def destroy
    @admin.destroy
    redirect_to admins_url, notice: "Admin was successfully deleted."
  end

  private

  def verify_params
    @admin.assign_attributes(user_params)

    if @admin.invalid?
      render json: {errors: @admin.errors.full_messages},
        status: :bad_request
    end
  end

  #
  # This is a temporary `verify_params` method that will exist until we migrate fully to the new permissions system
  #
  def 🆕verify_params
    if selected_facilities.blank?
      redirect_to edit_admin_path(@admin),
        alert: "At least one facility should be selected for access before inviting an Admin."

      return
    end

    @admin.assign_attributes(user_params)

    if @admin.invalid?
      redirect_to edit_admin_path,
        alert: @admin.errors.full_messages.join("")
    end
  end

  def set_admin
    @admin = User.find(params[:id])
    authorize([:manage, :admin, @admin])
  end

  def 🆕set_admin
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      @admin = authorize1 { current_admin.accessible_admins(:manage).find(params[:id]) }
      @admin = AdminAccessPresenter.new(@admin)
    end
  end

  def current_admin
    AdminAccessPresenter.new(super)
  end

  def permission_params
    params[:permissions]
  end

  def selected_facilities
    params[:facilities]
  end

  def user_params
    {
      full_name: params[:full_name],
      role: params[:role],
      access_level: params[:access_level],
      organization_id: params[:organization_id],
      device_updated_at: Time.current
    }.compact
  end

  def access_tree_for_page
    params[:page].to_sym
  end
end
