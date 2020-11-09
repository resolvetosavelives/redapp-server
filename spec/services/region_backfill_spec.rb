require "rails_helper"

RSpec.describe RegionBackfill, type: :model do
  context "dry run mode" do
    before do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, organization: org)
      _facility_group_2 = create(:facility_group, organization: org)
      create(:facility, facility_group: facility_group_1)
    end

    it "does not create any records" do
      expect {
        RegionBackfill.call(dry_run: true)
      }.to_not change { Region.count }
    end
  end

  context "write mode" do
    it "fails in countries other than India for now" do
      allow(CountryConfig).to receive(:current).and_return({name: "Bangladesh"})
      expect {
        RegionBackfill.call(dry_run: false)
      }.to raise_error(RegionBackfill::UnsupportedCountry)
    end

    it "backfills" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, name: "fg1", organization: org)
      facility_group_2 = create(:facility_group, name: "fg2", organization: org)
      _facility_group_3 = create(:facility_group, name: "fg3", organization: org)
      facility_group_4 = create(:facility_group, name: "fg4", organization: org)

      facility_1 = create(:facility, name: "facility1", facility_group: facility_group_1, block: "Block XYZ", state: "State 1")
      facility_2 = create(:facility, name: "facility2", facility_group: facility_group_1, block: "Block 123", state: "State 1")
      facility_3 = create(:facility, name: "facility3", facility_group: facility_group_2, block: "Block ZZZ", state: "State 2")
      facility_4 = create(:facility, name: "facility4", facility_group: facility_group_2, block: "Block ZZZ", state: "State 2")
      facility_5 = create(:facility, name: "facility5", facility_group: facility_group_4, block: "Block ABC", state: "State 1")
      facility_6 = create(:facility, name: "facility6", facility_group: facility_group_1, block: "Block 123", state: "State 1")
      facilities = [facility_1, facility_2, facility_3, facility_4, facility_5, facility_6]

      RegionBackfill.call(dry_run: false)
      RegionBackfill.call(dry_run: false)

      root = Region.find_by(name: "India")
      expect(root.root?).to be true
      expect(root.parent).to be_nil
      expect(root.region_type).to eq("root")
      expect(Region.root).to eq(root)

      org = root.children.first
      expect(org.children.map(&:name)).to contain_exactly("State 1", "State 2")
      expect(org.root).to eq(root)

      states = Region.state
      expect(states.count).to eq(2)
      expect(states.pluck(:slug)).to contain_exactly("state-1", "state-2")
      expect(states.pluck(:name)).to contain_exactly("State 1", "State 2")

      block_regions = Region.block
      expect(block_regions.size).to eq(4)
      expect(block_regions.map(&:name)).to contain_exactly("Block XYZ", "Block 123", "Block ZZZ", "Block ABC")

      facility_regions = Region.facility
      expect(facility_regions.size).to eq(6)

      expect(org.leaves.map(&:source)).to contain_exactly(*facilities)
      expect(org.leaves.map(&:region_type).uniq).to contain_exactly("facility")
    end

    it "works when there is are blocks and facilities that have the same name and slug" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, name: "fg1", organization: org)
      facility_group_2 = create(:facility_group, name: "fg2", organization: org)

      queens = create(:facility, name: "Queens", facility_group: facility_group_1, block: "New York", state: "State 1")
      new_york = create(:facility, name: "New York", facility_group: facility_group_1, block: "Other Block", state: "State 1")
      manhatten = create(:facility, name: "Manhatten", facility_group: facility_group_1, block: "New York", state: "State 1")
      east_village = create(:facility, name: "East Village", facility_group: facility_group_2, block: "New York", state: "State 2")
      other_new_york = create(:facility, name: "New York", facility_group: facility_group_2, block: "New York", state: "State 2")

      RegionBackfill.call(dry_run: false)

      expect(Region.root.facilities.map(&:source)).to contain_exactly(queens, new_york, manhatten, east_village, other_new_york)
      blocks = Region.root.blocks
      expect(blocks.size).to eq(3)
      expect(blocks.map(&:name)).to contain_exactly("New York", "Other Block", "New York")
      blocks.each do |block|
        next unless block.name == "New York"
        expect(block.slug).to match(/new-york/)
      end
      expect(queens.region.block).to eq(manhatten.region.block)
      expect(queens.region.block).to_not eq(east_village.region.block)
    end

    it "establishes associations from facility / facility group back to regions" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, organization: org)
      facility_group_2 = create(:facility_group, organization: org)

      facility_1 = create(:facility, name: "facility1", facility_group: facility_group_1)
      _facility_2 = create(:facility, name: "facility2", facility_group: facility_group_1)
      _facility_3 = create(:facility, name: "facility3", facility_group: facility_group_2)

      RegionBackfill.call(dry_run: false)

      region_f1 = facility_1.region
      expect(region_f1).to_not be_nil
      expect(region_f1.name).to eq(facility_1.name)
      expect(region_f1.region_type).to eq("facility")

      expect(region_f1.parent.name).to eq(facility_1.zone)
      expect(region_f1.parent.region_type).to eq("block")

      expect(region_f1.parent.parent).to eq(facility_1.facility_group.region)
    end

    it "is idempotent and does not create same data multiple times" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, name: "fg1", organization: org)
      facility_group_2 = create(:facility_group, name: "fg2", organization: org)
      _facility_group_3 = create(:facility_group, name: "fg3", organization: org)
      facility_group_4 = create(:facility_group, name: "fg4", organization: org)

      create(:facility, name: "facility1", facility_group: facility_group_1, block: "Block XYZ", state: "State 1")
      create(:facility, name: "facility2", facility_group: facility_group_1, block: "Block 123", state: "State 1")
      create(:facility, name: "facility3", facility_group: facility_group_2, block: "Block ZZZ", state: "State 2")
      create(:facility, name: "facility4", facility_group: facility_group_2, block: "Block ZZZ", state: "State 2")
      create(:facility, name: "facility5", facility_group: facility_group_4, block: "Block ABC", state: "State 1")
      create(:facility, name: "facility6", facility_group: facility_group_1, block: "Block 123", state: "State 1")

      3.times do
        RegionBackfill.call(dry_run: false)
      end

      # 1 org, 2 states, 4 districts, 4 blocks, 6 facilities
      expect(Region.count).to eq(17)
    end
  end
end
