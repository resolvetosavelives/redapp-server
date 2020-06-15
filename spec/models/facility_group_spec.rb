require "rails_helper"

RSpec.describe FacilityGroup, type: :model do
  describe "Associations" do
    it { should belong_to(:organization) }
    it { should have_many(:facilities) }

    it { have_many(:patients).through(:facilities) }
    it { have_many(:blood_pressures).through(:facilities) }
    it { have_many(:blood_sugars).through(:facilities) }
    it { have_many(:prescription_drugs).through(:facilities) }
    it { have_many(:appointments).through(:facilities) }
    it { have_many(:medical_histories).through(:patients) }
    it { have_many(:communications).through(:appointments) }

    it { belong_to(:protocol) }

    it "nullifies facility_group_id in facilities" do
      facility_group = FactoryBot.create(:facility_group)
      FactoryBot.create_list(:facility, 5, facility_group: facility_group)
      expect { facility_group.destroy }.not_to change { Facility.count }
      expect(Facility.where(facility_group: facility_group)).to be_empty
    end
  end

  describe "Validations" do
    it { should validate_presence_of(:name) }
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  describe "Attribute sanitization" do
    it "squishes and upcases the first letter of the name" do
      facility_group = FactoryBot.create(:facility_group, name: "facility  Group  ")
      expect(facility_group.name).to eq("Facility Group")
    end
  end
end
