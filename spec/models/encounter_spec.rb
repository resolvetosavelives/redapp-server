require 'rails_helper'

describe Encounter, type: :model do
  let!(:user) { create(:user) }
  let!(:facility) { create(:facility) }
  let!(:patient) { create(:patient, registration_facility: facility) }
  let!(:timezone_offset) { 3600 }

  context '#encountered_on' do
    it 'returns the encountered_on in the correct timezone' do
      Timecop.travel(DateTime.new(2019, 1, 1)) {
        expect(Encounter.generate_encountered_on(Time.now, 24 * 60 * 60)).to eq(Date.new(2019, 1, 2))
      }
    end
  end

  context '#generate)id' do
    it 'generates the same encounter id consistently' do
      id_1 = Encounter.generate_id(facility.id, patient.id, patient.recorded_at, timezone_offset)
      id_2 = Encounter.generate_id(facility.id, patient.id, patient.recorded_at, timezone_offset)

      expect(id_1).to eq(id_2)
    end
  end
end
