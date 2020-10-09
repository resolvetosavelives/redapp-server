class AdminsController < AdminController
  include Pagination
  include SearchHelper

  before_action :set_admin, only: [:show, :edit, :update, :access_tree, :destroy]
  before_action :verify_params, only: [:update]

  def index
    admins = current_admin.accessible_admins(:manage)
    authorize { admins.any? }

    @admins =
      if searching?
        paginate(admins.search_by_name_or_email(search_query))
      else
        paginate(admins.order("email_authentications.email"))
      end
  end

  def access_tree
    access_tree =
      case page_for_access_tree
      when :show
        AdminAccessPresenter.new(@admin).visible_access_tree
      when :new, :edit
        AdminAccessPresenter.new(current_admin).visible_access_tree
      else
        head :not_found and return
      end

    user_being_edited = page_for_access_tree.eql?(:edit) ? AdminAccessPresenter.new(@admin) : nil

    render partial: access_tree[:render_partial],
           locals: {
             tree: access_tree[:data],
             root: access_tree[:root],
             user_being_edited: user_being_edited,
             tree_depth: 0,
             page: page_for_access_tree,
           }
  end

  def show
  end

  def edit
  end

  def update
    User.transaction do
      @admin.update!(user_params)
      current_admin.grant_access(@admin, selected_facilities)
    end

    redirect_to admins_url, notice: "Admin was successfully updated."
  end

  def destroy
    @admin.destroy
    redirect_to admins_url, notice: "Admin was successfully deleted."
  end

  private

  def verify_params
    if validate_selected_facilities?
      flash[:alert] = "At least one facility should be selected for access before editing an Admin."
      render :edit, status: :bad_request

      return
    end

    if access_level_changed? && !current_admin.modify_access_level?
      raise UserAccess::NotAuthorizedError
    end

    @admin.assign_attributes(user_params)

    if @admin.invalid?
      flash[:alert] = @admin.errors.full_messages.join("")
      render :edit, status: :bad_request
    end
  end

  def set_admin
    @admin = authorize { current_admin.accessible_admins(:manage).find(params[:id]) }
  end

  def selected_facilities
    params[:facilities]
  end

  def user_params
    {
      full_name: params[:full_name],
      role: params[:role],
      organization_id: params[:organization_id],
      access_level: params[:access_level],
      device_updated_at: Time.current
    }.compact
  end

  def page_for_access_tree
    params[:page].to_sym
  end

  def access_level_changed?
    return false if user_params[:access_level].blank?

    @admin.access_level != user_params[:access_level]
  end

  def validate_selected_facilities?
    selected_facilities.blank? && user_params[:access_level] != User.access_levels[:power_user]
  end
end
