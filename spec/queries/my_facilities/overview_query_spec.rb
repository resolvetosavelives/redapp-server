require 'rails_helper'

RSpec.describe MyFacilities::OverviewQuery do

  describe '#inactive_facilities' do
    let!(:active_facility) { create(:facility) }
    let!(:inactive_facility) { create (:facility) }
    let!(:inactive_facility_with_zero_bps) { create (:facility) }
    let!(:blood_pressures_for_active_facility) { create_list(:blood_pressure, 10, facility: active_facility, recorded_at: Time.current) }
    let!(:blood_pressures_for_inactive_facility) { create_list(:blood_pressure, 9, facility: inactive_facility, recorded_at: Time.current) }
    let!(:encounters) do
      (blood_pressures_for_active_facility + blood_pressures_for_inactive_facility).each { |record|
        create(:encounter, :with_observables, patient: record.patient, observable: record, facility: record.facility) }
    end

    it 'should return only inactive facilities' do
      facility_ids = [active_facility.id, inactive_facility.id, inactive_facility_with_zero_bps.id]
      expect(described_class.new(Facility.where(id: facility_ids)).inactive_facilities)
        .to match_array([inactive_facility, inactive_facility_with_zero_bps])
    end
  end
end
