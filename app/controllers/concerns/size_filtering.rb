module SizeFiltering
  extend ActiveSupport::Concern

  included do
    before_action :set_size

    private

    def set_size
      @size = params[:size].present? ? params[:size] : 'All'
      session[:facility_size_filter] = @size
      @facility_sizes = Facility.facility_sizes.keys.reverse.append('unknown')
    end

    def selected_size_facilities(scope_namespace = [])
      if @size == 'All'
        policy_scope(scope_namespace.concat([Facility.all]))
      else
        @size = @size.map { |size| size == 'unknown'? nil : size } if @size.is_a? Array
        policy_scope(scope_namespace.concat([Facility.where(facility_size: @size)]))
      end
    end
  end
end