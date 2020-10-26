require "rails_helper"

RSpec.describe DistrictAnalyticsQuery do
  let!(:organization) { create(:organization) }
  let!(:facility_group) { create(:facility_group, name: "Bathinda", organization: organization) }
  let!(:facility_1) { create(:facility, facility_group: facility_group) }
  let!(:facility_2) { create(:facility, facility_group: facility_group) }
  let!(:facility_3) { create(:facility, facility_group: facility_group) }
  let!(:analytics) { DistrictAnalyticsQuery.new(facility_group, :month, 5) }
  let!(:current_month) { Date.current.beginning_of_month }

  let(:four_months_back) { current_month - 4.months }
  let(:three_months_back) { current_month - 3.months }
  let(:two_months_back) { current_month - 2.months }
  let(:one_month_back) { current_month - 1.months }

  context "when there is data available" do
    before do
      [four_months_back, three_months_back].each do |month|
        #
        # register patients in facility_1 and assign it facility_2
        #
        patients_1 = Timecop.travel(month) {
          create_list(
            :patient,
            3,
            :hypertension,
            registration_facility: facility_1,
            assigned_facility: facility_2
          )
        }

        #
        # register patients in facility_2 and assign it facility_3
        #
        patients_2 = Timecop.travel(month) {
          create_list(
            :patient,
            3,
            :hypertension,
            registration_facility: facility_2,
            assigned_facility: facility_3
          )
        }

        #
        # register patient without HTN in facility_2
        #
        Timecop.travel(month) do
          create(
            :patient,
            :without_hypertension,
            registration_facility: facility_2
          )
        end

        #
        # add blood_pressures next month to facility_1 & facility_2
        #
        Timecop.travel(month + 1.month) do
          patients_1.each do |patient|
            create(:blood_pressure, patient: patient, facility: facility_1)
          end

          patients_2.each do |patient|
            create(:blood_pressure, patient: patient, facility: facility_2)
          end
        end

        #
        # add blood_pressures after a couple of months to facility_1 & facility_2
        #
        Timecop.travel(month + 2.months) do
          patients_1.each do |patient|
            create(:blood_pressure, patient: patient, facility: facility_1)
          end

          patients_2.each do |patient|
            create(:blood_pressure, patient: patient, facility: facility_2)
          end
        end
      end
    end

    describe "#registered_patients_by_period" do
      context "considers only htn diagnosed patients" do
        it "groups the registered patients by facility and beginning of month" do
          expected_result =
            {
              facility_1.id =>
                {
                  registered_patients_by_period: {
                    four_months_back => 3,
                    three_months_back => 3
                  }
                },

              facility_2.id =>
                {
                  registered_patients_by_period: {
                    four_months_back => 3,
                    three_months_back => 3
                  }
                }
            }

          expect(analytics.registered_patients_by_period).to eq(expected_result)
        end
      end
    end

    describe "#total_patients" do
      context "considers only htn diagnosed patients" do
        it "groups the assigned patients by facility" do
          expected_result =
            {
              facility_2.id =>
                {
                  total_patients: 6
                },

              facility_3.id =>
                {
                  total_patients: 6
                }
            }

          expect(analytics.total_patients).to eq(expected_result)
        end
      end
    end

    describe "#total_registered_patients" do
      context "considers only htn diagnosed patients" do
        it "groups patients by registration facility" do
          expected_result =
            {
              facility_1.id =>
                {
                  total_registered_patients: 6
                },

              facility_2.id =>
                {
                  total_registered_patients: 6
                }
            }

          expect(analytics.total_registered_patients).to eq(expected_result)
        end
      end
    end

    describe "#follow_up_patients_by_period" do
      it "counts follow up BPs recorded at the facility in the period" do
        expected_result = {
          facility_1.id => {
            follow_up_patients_by_period: {
              three_months_back => 3,
              two_months_back => 6,
              one_month_back => 3
            }
          },

          facility_2.id => {
            follow_up_patients_by_period: {
              three_months_back => 3,
              two_months_back => 6,
              one_month_back => 3
            }
          }
        }

        expect(analytics.follow_up_patients_by_period).to eq(expected_result)
      end

      it "counts patients with multiple BPs in a single period as one patient" do
        patient = create(
          :patient,
          :hypertension,
          registration_facility: facility_1,
          assigned_facility: facility_2,
          recorded_at: three_months_back
        )

        create(:blood_pressure, patient: patient, facility: facility_1, recorded_at: two_months_back + 1.day)
        create(:blood_pressure, patient: patient, facility: facility_1, recorded_at: two_months_back + 2.days)
        create(:blood_pressure, patient: patient, facility: facility_1, recorded_at: two_months_back + 3.days)

        expected_result = {
          facility_1.id => {
            follow_up_patients_by_period: {
              three_months_back => 3,
              two_months_back => 7,
              one_month_back => 3
            }
          },

          facility_2.id => {
            follow_up_patients_by_period: {
              three_months_back => 3,
              two_months_back => 6,
              one_month_back => 3
            }
          }
        }

        expect(analytics.follow_up_patients_by_period).to eq(expected_result)
      end
    end

    describe "#patients_with_bp_by_period" do
      context "considers only htn diagnosed patients" do
        it "groups the assigned patient visits by facility and beginning of month" do
          expected_result =
            {
              facility_2.id =>
                {
                  patients_with_bp_by_period:
                    {
                      four_months_back => 0,
                      three_months_back => 3,
                      two_months_back => 6,
                      one_month_back => 3
                    }
                },

              facility_3.id =>
                {
                  patients_with_bp_by_period:
                    {
                      four_months_back => 0,
                      three_months_back => 3,
                      two_months_back => 6,
                      one_month_back => 3
                    }
                }
            }

          expect(analytics.patients_with_bp_by_period).to eq(expected_result)
        end
      end
    end

    context "facilities in the same district but belonging to different organizations" do
      let!(:facility_in_another_org) { create(:facility) }
      let!(:bp_in_another_org) { create(:blood_pressure, facility: facility_in_another_org) }

      it "does not contain data from a different organization" do
        expect(analytics.registered_patients_by_period.keys).not_to include(facility_in_another_org.id)
        expect(analytics.total_patients.keys).not_to include(facility_in_another_org.id)
        expect(analytics.patients_with_bp_by_period.keys).not_to include(facility_in_another_org.id)
      end
    end
  end

  context "when there is no data available" do
    it "returns nil for all analytics queries" do
      expect(analytics.registered_patients_by_period).to eq(nil)
      expect(analytics.total_patients).to eq(nil)
      expect(analytics.patients_with_bp_by_period).to eq(nil)
    end
  end

  context "for discarded patients" do
    let!(:patients) do
      Timecop.travel(four_months_back) do
        create_list(
          :patient,
          2,
          :hypertension,
          registration_facility: facility_2
        )
      end
    end

    before do
      Timecop.travel(three_months_back) do
        create(:blood_pressure, patient: patients.first, facility: facility_2)
        create(:blood_pressure, patient: patients.second, facility: facility_2)
      end

      patients.first.discard_data
    end

    describe "#registered_patients_by_period" do
      it "excludes count discarded patients" do
        expected_result =
          {
            facility_2.id =>
              {
                registered_patients_by_period: {
                  four_months_back => 1
                }
              }
          }

        expect(analytics.registered_patients_by_period).to eq(expected_result)
      end
    end

    describe "#patients_with_bp_by_period" do
      it "excludes count discarded patients" do
        expected_result =
          {
            facility_2.id =>
              {
                patients_with_bp_by_period: {
                  four_months_back => 0,
                  three_months_back => 1,
                  two_months_back => 0,
                  one_month_back => 0
                }
              }
          }

        expect(analytics.patients_with_bp_by_period).to eq(expected_result)
      end
    end

    describe "#total_assigned_patients" do
      it "excludes count discarded patients" do
        expected_result =
          {
            facility_2.id =>
              {
                total_patients: 1
              }
          }

        expect(analytics.total_patients).to eq(expected_result)
      end
    end
  end
end
