require "rails_helper"

RSpec.describe Reports::RegionsHelper, type: :helper do
  describe "#recent_bp_log" do
    it "orders bps by date descending" do
      Timecop.freeze("1 Jul 2021 1PM UTC") do
        bp_1 = create(:blood_pressure, recorded_at: 2.day.ago)
        bp_2 = create(:blood_pressure, recorded_at: 1.day.ago)

        expect(recent_bp_log(BloodPressure.all)).to eq([bp_2, bp_1])
      end
    end

    it "orders bps by time of day ascending for BPs on the same date" do
      Timecop.freeze("1 Jul 2021 1PM UTC") do
        bp_1 = create(:blood_pressure, recorded_at: 20.minutes.ago)
        bp_2 = create(:blood_pressure, recorded_at: 10.minutes.ago)

        expect(recent_bp_log(BloodPressure.all)).to eq([bp_1, bp_2])
      end
    end

    context "respects the reporting timezone for ordering" do
      it "BPs in different days in reporting time zone but same day in UTC are ordered descending" do
        bp_1 = create(:blood_pressure, recorded_at: Time.parse("1 July 2021 11:30PM IST"))
        bp_2 = create(:blood_pressure, recorded_at: Time.parse("2 July 2021 12:30AM IST"))

        expect(recent_bp_log(BloodPressure.all)).to eq([bp_2, bp_1])
      end
    end
  end
end
