require "rails_helper"

RSpec.describe DrugStocksQuery do
  let!(:state) { "Punjab" }
  let(:zone) { "Block A" }
  let!(:protocol) { create(:protocol, :with_tracked_drugs) }
  let!(:facility_group) { create(:facility_group, protocol: protocol) }
  let!(:user) { create(:admin, :manager, :with_access, resource: facility_group) }
  let!(:for_end_of_month) { Time.current.end_of_month }
  let!(:drug_category) { "hypertension_ccb" }
  let!(:stocks_by_rxnorm) {
    {"329528" => {in_stock: 10000, received: 2000, redistributed: 1000},
     "329526" => {in_stock: 20000, received: 2000, redistributed: 0},
     "316764" => {in_stock: 10000, received: 2000, redistributed: 0},
     "316765" => {in_stock: 20000, received: 2000, redistributed: 0},
     "979467" => {in_stock: 10000, received: 2000, redistributed: 0}}
  }
  let!(:previous_month_stocks_by_rxnorm) {
    {
      "329528" => {in_stock: 8000, redistributed: 0},
      "329526" => {in_stock: 15000, redistributed: 0},
      "316764" => {in_stock: 8000, redistributed: 0},
      "316765" => {in_stock: 17000, redistributed: 0},
      "979467" => {in_stock: 9000, redistributed: 0}
    }
  }
  let!(:punjab_drug_stock_config) {
    {"load_coefficient" => 1,
     "drug_categories" =>
        {"hypertension_ccb" => {"new_patient_coefficient" => 1.4, "329528" => 1.2, "329526" => 2},
         "hypertension_arb" => {"new_patient_coefficient" => 0.37, "316764" => 1, "316765" => 2, "979467" => 1},
         "hypertension_diuretic" => {"new_patient_coefficient" => 0.06, "316049" => 1, "331132" => 1}}}.with_indifferent_access
  }

  context "drug stock report" do
    let!(:facilities) { create_list(:facility, 3, facility_group: facility_group, state: state, zone: zone) }
    let!(:patients) {
      facilities.map { |facility|
        create_list(:patient, 3, registration_facility: facility, registration_user: user) <<
          create(:patient, recorded_at: 2.years.ago, registration_facility: facility, registration_user: user) # ltfu patient
      }.flatten
    }

    let!(:drug_stocks) {
      facilities.map { |facility|
        stocks_by_rxnorm.map do |(rxnorm_code, drug_stock)|
          protocol_drug = protocol.protocol_drugs.find_by(rxnorm_code: rxnorm_code)
          create(:drug_stock,
            user: user,
            facility: facility,
            protocol_drug: protocol_drug,
            in_stock: drug_stock[:in_stock],
            redistributed: drug_stock[:redistributed])
        end
      }.flatten
    }

    before do
      allow_any_instance_of(Reports::DrugStockCalculation).to receive(:patient_days_coefficients).and_return(punjab_drug_stock_config)
      RefreshMaterializedViews.call
    end

    it "computes the drug stock report totals" do
      result = described_class.new(facilities: facilities,
                                   for_end_of_month: for_end_of_month,
                                   include_block_report: true).drug_stocks_report

      expect(result[:patient_count]).to eq(9)
      expect(result[:patient_days]["hypertension_ccb"][:patient_days]).to eq(12380)
      expect(result[:patient_days]["hypertension_arb"][:patient_days]).to eq(54054)

      {"hypertension_ccb" => %w[329528 329526],
       "hypertension_arb" => %w[316764 316765 979467]}.each do |(drug_category, rxnorm_codes)|
        expect(result[:patient_days][drug_category][:stocks_on_hand]).not_to be_nil
        expect(result[:patient_days][drug_category][:load_coefficient]).not_to be_nil
        expect(result[:patient_days][drug_category][:new_patient_coefficient]).not_to be_nil
        expect(result[:patient_days][drug_category][:estimated_patients]).not_to be_nil
        expect(result[:patient_days][drug_category][:patient_days]).not_to be_nil

        rxnorm_codes.each do |rxnorm_code|
          expected_total_stock = stocks_by_rxnorm[rxnorm_code][:in_stock] * facilities.count
          expect(result[:drugs_in_stock][rxnorm_code]).to eq(expected_total_stock)
        end
      end
    end

    it "computes the drug stock report facility wise numbers" do
      result = described_class.new(facilities: facilities,
                                   for_end_of_month: for_end_of_month,
                                   include_block_report: true).drug_stocks_report
      facility = facilities.first

      expect(result[:patient_count_by_facility_id][facility.id]).to eq(3)
      expect(result[:patient_days_by_facility_id][facility.id]["hypertension_ccb"][:patient_days]).to eq(12380)
      expect(result[:patient_days_by_facility_id][facility.id]["hypertension_arb"][:patient_days]).to eq(54054)

      {"hypertension_ccb" => %w[329528 329526],
       "hypertension_arb" => %w[316764 316765 979467]}.each do |(drug_category, rxnorm_codes)|
        expect(result[:patient_days_by_facility_id][facility.id][drug_category][:stocks_on_hand]).not_to be_nil
        expect(result[:patient_days_by_facility_id][facility.id][drug_category][:load_coefficient]).not_to be_nil
        expect(result[:patient_days_by_facility_id][facility.id][drug_category][:new_patient_coefficient]).not_to be_nil
        expect(result[:patient_days_by_facility_id][facility.id][drug_category][:estimated_patients]).not_to be_nil
        expect(result[:patient_days_by_facility_id][facility.id][drug_category][:patient_days]).not_to be_nil

        rxnorm_codes.each do |rxnorm_code|
          expected_total_stock = stocks_by_rxnorm[rxnorm_code][:in_stock]
          expect(result[:drugs_in_stock_by_facility_id][[facility.id, rxnorm_code]]).to eq(expected_total_stock)
        end
      end
    end

    it "computes the drug stock report block wise numbers" do
      facility_in_another_block =
        create(:facility, facility_group: facility_group, state: state, zone: "Block B")
      block_a = facilities.first.block_region
      block_b = facility_in_another_block.block_region

      result = described_class.new(facilities: facilities + [facility_in_another_block],
                                   for_end_of_month: for_end_of_month,
                                   include_block_report: true).drug_stocks_report

      expect(result[:patient_count_by_block_id][block_a.id]).to eq(9)
      expect(result[:patient_count_by_block_id][block_b.id]).to eq(0)
      expect(result[:patient_days_by_block_id][block_a.id]["hypertension_ccb"][:patient_days]).to eq(12380)
      expect(result[:patient_days_by_block_id][block_b.id]["hypertension_ccb"]).to be_nil
      expect(result[:patient_days_by_block_id][block_a.id]["hypertension_arb"][:patient_days]).to eq(54054)
      expect(result[:patient_days_by_block_id][block_b.id]["hypertension_arb"]).to be_nil

      {"hypertension_ccb" => %w[329528 329526],
       "hypertension_arb" => %w[316764 316765 979467]}.each do |(drug_category, rxnorm_codes)|
        expect(result[:patient_days_by_block_id][block_a.id][drug_category][:stocks_on_hand]).not_to be_nil
        expect(result[:patient_days_by_block_id][block_a.id][drug_category][:load_coefficient]).not_to be_nil
        expect(result[:patient_days_by_block_id][block_a.id][drug_category][:new_patient_coefficient]).not_to be_nil
        expect(result[:patient_days_by_block_id][block_a.id][drug_category][:estimated_patients]).not_to be_nil
        expect(result[:patient_days_by_block_id][block_a.id][drug_category][:patient_days]).not_to be_nil

        rxnorm_codes.each do |rxnorm_code|
          expected_total_stock = stocks_by_rxnorm[rxnorm_code][:in_stock] * block_a.facilities.count
          expect(result[:drugs_in_stock_by_block_id][[block_a.id, rxnorm_code]]).to eq(expected_total_stock)
        end
      end
    end

    it "does not compute block wise numbers when include_block_report is false" do
      result = described_class.new(facilities: facilities,
                                   for_end_of_month: for_end_of_month,
                                   include_block_report: false).drug_stocks_report

      expect(result[:patient_count_by_block_id]).to eq(nil)
      expect(result[:patient_days_by_block_id]).to eq(nil)
      expect(result[:drugs_in_stock_by_block_id]).to eq(nil)
    end

    it "skips drug categories when drug stocks are not present" do
      instance = described_class.new(facilities: facilities,
                                     for_end_of_month: for_end_of_month,
                                     include_block_report: true)
      result = instance.drug_stocks_report

      expect(result[:patient_days]["hypertension_diuretic"]).to eq(nil)
      expect(result[:drugs_in_stock]["331132"]).to eq(nil)
    end

    it "skips computing drug stock report when there are no drug stocks or patients for a facility" do
      facility_without_drug_stocks = create(:facility, facility_group: facilities.first.facility_group)

      instance = described_class.new(facilities: Facility.where(id: facility_without_drug_stocks),
                                     for_end_of_month: for_end_of_month,
                                     include_block_report: true)
      result = instance.drug_stocks_report

      expect(result[:patient_count_by_facility_id][facility_without_drug_stocks.id]).to eq(0)
      expect(result[:patient_days_by_facility_id][facility_without_drug_stocks.id]).to eq({"hypertension_arb" => nil,
                                                                                           "hypertension_ccb" => nil,
                                                                                           "hypertension_diuretic" => nil})
    end

    describe "#drug_stocks_cache_key" do
      it "caches for a given set of facilities and month" do
        facilities = create_list(:facility, 3, facility_group: facility_group)

        ck_this_month = described_class.new(facilities: facilities,
                                            for_end_of_month: Date.today.end_of_month,
                                            include_block_report: true).drug_stocks_cache_key
        ck_next_month = described_class.new(facilities: facilities,
                                            for_end_of_month: 1.month.from_now.end_of_month,
                                            include_block_report: true).drug_stocks_cache_key
        expect(ck_this_month).not_to eq(ck_next_month)

        facility = create(:facility, facility_group: facility_group)
        ck_this_month_with_facility = described_class.new(facilities: facilities << facility,
                                                          for_end_of_month: Date.today.end_of_month,
                                                          include_block_report: true).drug_stocks_cache_key
        expect(ck_this_month).not_to eq(ck_this_month_with_facility)
      end
    end
  end

  context "drug consumption report" do
    let!(:facilities) { create_list(:facility, 3, facility_group: facility_group, state: state, zone: zone) }

    let!(:patients) {
      facilities.map { |facility|
        create_list(:patient, 3, registration_facility: facility, registration_user: user)
      }.flatten
    }

    let!(:drug_stocks) {
      facilities.map { |facility|
        stocks_by_rxnorm.map do |(rxnorm_code, drug_stock)|
          protocol_drug = protocol.protocol_drugs.find_by(rxnorm_code: rxnorm_code)
          create(:drug_stock,
            user: user,
            facility: facility,
            protocol_drug: protocol_drug,
            in_stock: drug_stock[:in_stock],
            received: drug_stock[:received],
            redistributed: drug_stock[:redistributed])
        end
      }.flatten
    }

    let!(:previous_month_drug_stocks) {
      facilities.map { |facility|
        stocks_by_rxnorm.map do |(rxnorm_code, drug_stock)|
          protocol_drug = protocol.protocol_drugs.find_by(rxnorm_code: rxnorm_code)
          create(:drug_stock,
            user: user,
            facility: facility,
            protocol_drug: protocol_drug,
            in_stock: drug_stock[:in_stock],
            for_end_of_month: (Date.today - 1.month).end_of_month)
        end
      }.flatten
    }

    before do
      allow_any_instance_of(Reports::DrugStockCalculation).to receive(:patient_days_coefficients).and_return(punjab_drug_stock_config)
    end

    it "computes the drug consumption report totals" do
      result = described_class.new(facilities: facilities,
                                   for_end_of_month: for_end_of_month,
                                   include_block_report: true).drug_consumption_report

      expect(result[:patient_count]).to eq(patients.count)
      expect(result[:all_drug_consumption]["hypertension_ccb"][:base_doses][:total]).to eq(15600)
      expect(result[:all_drug_consumption]["hypertension_arb"][:base_doses][:total]).to eq(24000)

      {"hypertension_ccb" => %w[329528 329526],
       "hypertension_arb" => %w[316764 316765 979467]}.each do |(drug_category, rxnorm_codes)|
        expect(result[:all_drug_consumption][drug_category][:base_doses][:total]).not_to be_nil
        expect(result[:all_drug_consumption][drug_category][:base_doses][:drugs]).not_to be_nil
        expect(result[:all_drug_consumption][drug_category][:base_doses][:drugs].first[:name]).not_to be_nil
        expect(result[:all_drug_consumption][drug_category][:base_doses][:drugs].first[:consumed]).not_to be_nil
        expect(result[:all_drug_consumption][drug_category][:base_doses][:drugs].first[:coefficient]).not_to be_nil
      end
    end

    it "computes the drug consumption report for facilities" do
      result = described_class.new(facilities: facilities,
                                   for_end_of_month: for_end_of_month,
                                   include_block_report: true).drug_consumption_report
      facility = facilities.first
      expect(result[:patient_count_by_facility_id][facility.id]).to eq(3)
      expect(result[:drug_consumption_by_facility_id][facility.id]["hypertension_ccb"][:base_doses][:total]).to eq(5200)
      expect(result[:drug_consumption_by_facility_id][facility.id]["hypertension_arb"][:base_doses][:total]).to eq(8000)

      {"hypertension_ccb" => %w[329528 329526],
       "hypertension_arb" => %w[316764 316765 979467]}.each do |(drug_category, rxnorm_codes)|
        expect(result[:drug_consumption_by_facility_id][facility.id][drug_category][:base_doses][:total]).not_to be_nil
        expect(result[:drug_consumption_by_facility_id][facility.id][drug_category][:base_doses][:drugs]).not_to be_nil
        expect(result[:drug_consumption_by_facility_id][facility.id][drug_category][:base_doses][:drugs].first[:name]).not_to be_nil
        expect(result[:drug_consumption_by_facility_id][facility.id][drug_category][:base_doses][:drugs].first[:consumed]).not_to be_nil
        expect(result[:drug_consumption_by_facility_id][facility.id][drug_category][:base_doses][:drugs].first[:coefficient]).not_to be_nil
      end

      drug = ProtocolDrug.find_by_rxnorm_code("329528")
      expect(result[:drug_consumption_by_facility_id][facility.id][drug_category][drug]).to eq({opening_balance: 10000,
                                                                                                received: 2000,
                                                                                                closing_balance: 10000,
                                                                                                consumed: 1000,
                                                                                                redistributed: 1000})
    end

    it "computes the drug consumption report for blocks" do
      facility_in_another_block =
        create(:facility, facility_group: facility_group, state: state, zone: "Block B")
      block_a = facilities.first.block_region
      block_b = facility_in_another_block.block_region

      result = described_class.new(facilities: facilities << facility_in_another_block,
                                   for_end_of_month: for_end_of_month,
                                   include_block_report: true).drug_consumption_report

      expect(result[:patient_count_by_block_id][block_a.id]).to eq(9)
      expect(result[:drug_consumption_by_block_id][block_a.id]["hypertension_ccb"][:base_doses][:total]).to eq(15600)
      expect(result[:drug_consumption_by_block_id][block_b.id]["hypertension_ccb"][:base_doses][:total]).to be_nil
      expect(result[:drug_consumption_by_block_id][block_a.id]["hypertension_arb"][:base_doses][:total]).to eq(24000)
      expect(result[:drug_consumption_by_block_id][block_b.id]["hypertension_arb"][:base_doses][:total]).to be_nil

      {"hypertension_ccb" => %w[329528 329526],
       "hypertension_arb" => %w[316764 316765 979467]}.each do |(drug_category, rxnorm_codes)|
        expect(result[:drug_consumption_by_block_id][block_a.id][drug_category][:base_doses][:total]).not_to be_nil
        expect(result[:drug_consumption_by_block_id][block_a.id][drug_category][:base_doses][:drugs]).not_to be_nil
        expect(result[:drug_consumption_by_block_id][block_a.id][drug_category][:base_doses][:drugs].first[:name]).not_to be_nil
        expect(result[:drug_consumption_by_block_id][block_a.id][drug_category][:base_doses][:drugs].first[:consumed]).not_to be_nil
        expect(result[:drug_consumption_by_block_id][block_a.id][drug_category][:base_doses][:drugs].first[:coefficient]).not_to be_nil
      end

      drug = ProtocolDrug.find_by_rxnorm_code("329528")
      expect(result[:drug_consumption_by_block_id][block_a.id][drug_category][drug]).to eq({opening_balance: 30000,
                                                                                            received: 6000,
                                                                                            closing_balance: 30000,
                                                                                            consumed: 3000,
                                                                                            redistributed: 3000})
    end

    it "does not compute block wise numbers when include_block_report is false" do
      result = described_class.new(facilities: facilities,
                                   for_end_of_month: for_end_of_month,
                                   include_block_report: false).drug_consumption_report

      expect(result[:patient_count_by_block_id]).to eq(nil)
      expect(result[:drug_consumption_by_block_id]).to eq(nil)
    end

    describe "#drug_consumption_cache_key" do
      it "caches for a given set of facilities and month" do
        facilities = create_list(:facility, 3, facility_group: facility_group)

        ck_this_month = described_class.new(facilities: facilities,
                                            for_end_of_month: Date.today.end_of_month,
                                            include_block_report: true).drug_consumption_cache_key
        ck_next_month = described_class.new(facilities: facilities,
                                            for_end_of_month: 1.month.from_now.end_of_month,
                                            include_block_report: true).drug_consumption_cache_key
        expect(ck_this_month).not_to eq(ck_next_month)

        facility = create(:facility, facility_group: facility_group)
        ck_this_month_with_facility = described_class.new(facilities: facilities << facility,
                                                          for_end_of_month: Date.today.end_of_month,
                                                          include_block_report: true).drug_consumption_cache_key
        expect(ck_this_month).not_to eq(ck_this_month_with_facility)
      end
    end
  end
end
