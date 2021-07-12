class DrugStocksQuery
  include Memery

  CACHE_VERSION = 1

  def initialize(facility_group:, facilities:, for_end_of_month:, blocks: Region.none)
    @facilities = facilities
    @for_end_of_month = for_end_of_month
    @period = Period.month(@for_end_of_month)
    @protocol = facility_group.protocol
    @state = facility_group.state
    @latest_drug_stocks = DrugStock.latest_for_facilities(@facilities, @for_end_of_month)
    @blocks = blocks
  end

  attr_reader :for_end_of_month, :facilities, :blocks

  def drug_stocks_report
    Rails.cache.fetch(drug_stocks_cache_key,
      expires_in: ENV.fetch("ANALYTICS_DASHBOARD_CACHE_TTL"),
      force: RequestStore.store[:bust_cache]) do
      {patient_count: total_patients,
       patient_days: all_patient_days,
       drugs_in_stock: all_drugs_in_stock,
       patient_count_by_facility_id: patient_count_by_facility_id,
       patient_days_by_facility_id: patient_days_by_facility_id,
       drugs_in_stock_by_facility_id: drugs_in_stock_by_facility_id,
       patient_count_by_block_id: patient_count_by_block_id,
       patient_days_by_block_id: patient_days_by_block_id,
       drugs_in_stock_by_block_id: drugs_in_stock_by_block_id,
       last_updated_at: Time.now}
    end
  end

  def drug_consumption_report
    Rails.cache.fetch(drug_consumption_cache_key,
      expires_in: ENV.fetch("ANALYTICS_DASHBOARD_CACHE_TTL"),
      force: RequestStore.store[:bust_cache]) do
      {patient_count: total_patients,
       all_drug_consumption: all_drug_consumption,
       drug_consumption_by_facility_id: drug_consumption_by_facility_id,
       patient_count_by_facility_id: patient_count_by_facility_id,
       drug_consumption_by_block_id: drug_consumption_by_block_id,
       patient_count_by_block_id: patient_count_by_block_id,
       last_updated_at: Time.now}
    end
  end

  memoize def drugs
    @protocol.protocol_drugs.where(stock_tracked: true).load
  end

  memoize def protocol_drugs_by_category
    drugs
      .sort_by(&:sort_key)
      .group_by(&:drug_category)
      .sort_by { |(drug_category, _)| drug_category }
      .to_h
  end

  memoize def drug_categories
    drugs.pluck(:drug_category).uniq
  end

  memoize def repository
    Reports::Repository.new(@facilities, periods: @period)
  end

  memoize def patient_count_by_facility_id
    @facilities.each_with_object(Hash.new(0)) do |facility, result|
      result[facility.id] =
        repository.cumulative_assigned_patients[facility.slug][@period] -
        repository.ltfu[facility.slug][@period]
    end
  end

  memoize def patient_count_by_block_id
    @facilities.with_block_region_id.pluck("facilities.id", "block_region.id").each_with_object(Hash.new(0)) do |(facility_id, block_region_id), result|
      result[block_region_id] += patient_count_by_facility_id[facility_id]
    end
  end

  memoize def total_patients
    patient_count_by_facility_id.values.sum
  end

  memoize def selected_month_drug_stocks
    DrugStock
      .latest_for_facilities_cte(@facilities, @for_end_of_month)
      .with_block_region_id
      .load
  end

  memoize def previous_month_drug_stocks
    DrugStock
      .latest_for_facilities_cte(@facilities, end_of_previous_month)
      .with_block_region_id
      .load
  end

  def all_drugs_in_stock
    selected_month_drug_stocks.group("protocol_drugs.rxnorm_code").sum(:in_stock)
  end

  def drugs_in_stock_by_facility_id
    selected_month_drug_stocks.group(:facility_id, "protocol_drugs.rxnorm_code").sum(:in_stock)
  end

  def drugs_in_stock_by_block_id
    selected_month_drug_stocks
      .group("block_region_id", "protocol_drugs.rxnorm_code")
      .sum(:in_stock)
  end

  def patient_days_by_facility_id
    @facilities.pluck(:id).product(drug_categories).each_with_object({}) do |(facility_id, drug_category), result|
      result[facility_id] ||= {}
      result[facility_id][drug_category] = category_patient_days(
        drug_category,
        selected_month_drug_stocks.select { |drug_stock| drug_stock.facility_id == facility_id },
        patient_count_by_facility_id[facility_id] || 0
      )
    end
  end

  def patient_days_by_block_id
    @blocks.pluck(:id).product(drug_categories).each_with_object({}) do |(block_id, drug_category), result|
      result[block_id] ||= {}
      result[block_id][drug_category] = category_patient_days(
        drug_category,
        selected_month_drug_stocks.select { |drug_stock| drug_stock.block_region_id == block_id },
        patient_count_by_block_id[block_id] || 0
      )
    end
  end

  def all_patient_days
    drug_categories.each_with_object(Hash.new(0)) do |drug_category, result|
      result[drug_category] = category_patient_days(
        drug_category,
        selected_month_drug_stocks,
        total_patients
      )
    end
  end

  def category_patient_days(drug_category, category_drug_stocks, patient_count)
    Reports::DrugStockCalculation.new(
      state: @state,
      protocol_drugs: drugs,
      drug_category: drug_category,
      current_drug_stocks: category_drug_stocks,
      patient_count: patient_count
    ).patient_days
  end

  memoize def drug_consumption_by_facility_id
    @facilities.pluck(:id).product(drug_categories).each_with_object({}) do |(facility_id, drug_category), result|
      result[facility_id] ||= {}
      result[facility_id][drug_category] =
        category_drug_consumption(
          drug_category,
          selected_month_drug_stocks.select { |drug_stock| drug_stock.facility_id == facility_id },
          previous_month_drug_stocks.select { |drug_stock| drug_stock.facility_id == facility_id }
        )
    end
  end

  memoize def drug_consumption_by_block_id
    @blocks.pluck(:id).product(drug_categories).each_with_object({}) do |(block_id, drug_category), result|
      result[block_id] ||= {}
      result[block_id][drug_category] =
        category_drug_consumption(
          drug_category,
          selected_month_drug_stocks.select { |drug_stock| drug_stock.block_region_id == block_id },
          previous_month_drug_stocks.select { |drug_stock| drug_stock.block_region_id == block_id }
        )
    end
  end

  def all_drug_consumption
    drug_categories.each_with_object(Hash.new(0)) do |drug_category, result|
      result[drug_category] = category_drug_consumption(
        drug_category,
        selected_month_drug_stocks,
        previous_month_drug_stocks
      )
    end
  end

  def category_drug_consumption(drug_category, current_drug_stocks, previous_drug_stocks)
    Reports::DrugStockCalculation.new(
      state: @state,
      protocol_drugs: drugs,
      drug_category: drug_category,
      current_drug_stocks: current_drug_stocks,
      previous_drug_stocks: previous_drug_stocks
    ).consumption
  end

  memoize def end_of_previous_month
    (@for_end_of_month - 1.month).end_of_month
  end

  def drug_stocks_cache_key
    [
      "#{self.class.name}#drug_stocks",
      @facilities.map(&:id).sort,
      @latest_drug_stocks.cache_key,
      @for_end_of_month,
      @protocol.id,
      @state,
      CACHE_VERSION
    ].join("/")
  end

  def drug_consumption_cache_key
    [
      "#{self.class.name}#drug_consumption",
      @facilities.map(&:id).sort,
      @for_end_of_month,
      @protocol.id,
      @state,
      CACHE_VERSION
    ].join("/")
  end
end
