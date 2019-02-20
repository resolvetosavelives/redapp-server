require 'rails_helper'

describe AppointmentsHelper do
  context '#blood_pressure_recorded_date' do
    it 'should return Today if date is less than 24 hours' do
      date = Date.today
      expect(blood_pressure_recorded_date(date)).to eq("Today")
    end

    it 'should return Yesterday if date is from yesterday' do
      date = Date.yesterday
      expect(blood_pressure_recorded_date(date)).to eq("Yesterday")
    end

    it 'should return date in dd/mm/yyyy format if date is more than a year' do
      date = Date.parse('31-12-2016')
      expect(blood_pressure_recorded_date(date)).to eq("31/12/2016")
    end

    it 'should return date in number of ago if date is less than a year ago' do
      expect(blood_pressure_recorded_date(31.days.ago.to_date)).to eq("about 1 month ago")
      expect(blood_pressure_recorded_date(2.months.ago.to_date)).to eq("2 months ago")
      expect(blood_pressure_recorded_date(11.months.ago.to_date)).to eq("11 months ago")
    end
  end
end
