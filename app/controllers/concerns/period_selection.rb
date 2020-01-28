# frozen_string_literal: true

module PeriodSelection
  extend ActiveSupport::Concern

  included do
    before_action :populate_periods, :set_selected_period

    def set_selected_period
      @selected_period = params[:period].blank? ? :quarter : params[:period].to_sym
    end

    def populate_periods
      @periods = { quarter: 'Quarterly', month: 'Monthly', day: 'Daily' }
    end
  end
end
