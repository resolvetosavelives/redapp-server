require "rails_helper"
require "tasks/scripts/delete_organization_data"

RSpec.describe DeleteOrganizationData do
  describe ".call" do
    let!(:organization) { create(:organization) }
    let!(:facility_group) { create(:facility_group, organization: organization) }
    let!(:facilities) { create_list(:facility, 2, facility_group: facility_group) }
    let!(:patients) { facilities.map { |facility| create_list(:patient, 2, registration_facility: facility) }.flatten }
    let!(:blood_pressures) { patients.map { |patient| create_list(:blood_pressure, 2, patient: patient) }.flatten }
    let!(:blood_sugars) { patients.map { |patient| create_list(:blood_sugar, 2, patient: patient) }.flatten }

    it "deletes an org and associated data" do
      described_class.call(organization_id: organization.id, dry_run: false)

      expect { organization.reload }.to raise_error ActiveRecord::RecordNotFound
      expect { facility_group.reload }.to raise_error ActiveRecord::RecordNotFound
      facilities.each { |facility| expect { facility.reload }.to raise_error ActiveRecord::RecordNotFound }
      patients.each { |patient| expect { patient.reload }.to raise_error ActiveRecord::RecordNotFound }
      blood_pressures.each { |blood_pressure| expect { blood_pressure.reload }.to raise_error ActiveRecord::RecordNotFound }
      blood_sugars.each { |blood_sugar| expect { blood_sugar.reload }.to raise_error ActiveRecord::RecordNotFound }
    end

    it "does not delete things from other orgs" do
      other_organizations = create_list(:organization, 2)
      other_facility_groups = other_organizations.map { |org| create_list(:facility_group, 2, organization: org) }
      other_facilities = other_facility_groups.map { |fg| create_list(:facility, 2, facility_group: fg) }

      described_class.call(organization_id: facility.facility_group.organization_id, dry_run: false)
      expect(other_organizations.reload).to eq other_organizations
      expect(other_facility_groups.reload).to eq other_facility_groups
      expect(other_facilities.reload).to eq other_facilities
    end
  end
end
