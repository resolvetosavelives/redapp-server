class Manage::User::UserPolicy < ApplicationPolicy
  def index?
    user.user_permissions
      .where(permission_slug: :approve_health_workers)
      .present?
  end

  def show?
    user_has_any_permissions?(
      [:approve_health_workers, nil],
      [:approve_health_workers, record.organization],
      [:approve_health_workers, record.facility_group]
    )
  end

  def update?
    show?
  end

  def edit?
    update?
  end

  def disable_access?
    update?
  end

  def enable_access?
    update?
  end

  def reset_otp?
    update?
  end

  def destroy?
    false
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      super
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?(:approve_health_workers)

      facility_group_ids = facility_group_ids_for_permission(:approve_health_workers)
      user_scope = scope.joins(:phone_number_authentications)
        .where.not(phone_number_authentications: {id: nil})

      return user_scope.all if facility_group_ids.blank?

      facilities = ::Facility.where(facility_group_id: facility_group_ids)
      user_scope.where(phone_number_authentications:
                         {registration_facility_id: facilities})
    end
  end
end
