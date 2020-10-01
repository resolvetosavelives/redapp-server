require "rails_helper"

RSpec.describe RegionBackfill, type: :model do
  before do
    # duplicating this from the data migration for now
    instance = RegionKind.create! name: "Root", path: "Root"
    org = RegionKind.create! name: "Organization", parent: instance
    facility_group = RegionKind.create! name: "FacilityGroup", parent: org
    block = RegionKind.create! name: "Block", parent: facility_group
    _facility = RegionKind.create! name: "Facility", parent: block
  end

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

    it "logs attributes of records it would create" do
      expect(Rails.logger).to receive(:info).with(msg: "create", region: hash_including(name: "India")).exactly(1).times
      expect(Rails.logger).to receive(:info).with(msg: "save", region: instance_of(Hash)).at_least(3).times
      RegionBackfill.call(dry_run: true)
    end
  end

  context "write mode" do
    it "backfills" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, organization: org)
      facility_group_2 = create(:facility_group, organization: org)

      facility_1 = create(:facility, name: "facility1", facility_group: facility_group_1)
      facility_2 = create(:facility, name: "facility2", facility_group: facility_group_1)

      facility_3 = create(:facility, name: "facility3", facility_group: facility_group_2)

      RegionBackfill.call(dry_run: false)

      root = Region.find_by(name: "India")
      expect(root.root?).to be true
      org = root.children.first
      expect(org.children.map(&:source)).to contain_exactly(facility_group_1, facility_group_2)

      block_regions = Region.where(kind: RegionKind.find_by!(name: "Block"))
      expect(block_regions.size).to eq(2)
      expect(block_regions.map(&:name).uniq).to eq(["Block ABC"])

      expect(org.leaves.map(&:source)).to contain_exactly(facility_1, facility_2, facility_3)
      expect(org.leaves.map(&:kind).uniq).to contain_exactly(RegionKind.find_by!(name: "Facility"))
    end
  end
end
