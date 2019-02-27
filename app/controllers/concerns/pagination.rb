module Pagination
  extend ActiveSupport::Concern

  DEFAULT_PAGE_SIZE = 20

  included do
    before_action :set_page, only: [:index]
    before_action :set_per_page, only: [:index]

    private

    def set_page
      @page = params[:page]
    end

    def set_per_page
      @per_page = params[:per_page] || DEFAULT_PAGE_SIZE
    end

    def paginate(records)
      records
        .page(@page)
        .per(@per_page == "All" ? records.size : @per_page.to_i)
    end
  end
end
