require "features_helper"

RSpec.feature "Overdue appointments", type: :feature do
  let!(:ihmi) { create(:organization, name: "IHMI") }
  let!(:ihmi_group) { create(:facility_group, organization: ihmi) }
  let!(:facility) { create(:facility, facility_group: ihmi_group) }
  let!(:call_center) { create(:admin, :call_center) }

  before do
    call_center.accesses.create(resource: ihmi)
    ENV["IHCI_ORGANIZATION_UUID"] = ihmi.id
  end

  describe "index" do
    before { sign_in(call_center.email_authentication) }

    it "shows Overdue tab" do
      visit root_path

      expect(page).to have_content("Overdue patients")
    end

    describe "Overdue patients tab" do
      let!(:authorized_facility_group) { ihmi_group }

      let!(:facility_1) { create(:facility, facility_group: authorized_facility_group) }

      let!(:overdue_patient_in_facility_1) do
        patient = create(:patient, full_name: "patient_1", registration_facility: facility_1)
        create(:appointment, :overdue, facility: facility_1, patient: patient, scheduled_date: 10.days.ago)
        create(:blood_pressure, :critical, facility: facility_1, patient: patient)
        patient
      end

      let!(:non_overdue_patient_in_facility_1) { create(:patient, full_name: "patient_2", registration_facility: facility_1) }

      let!(:facility_2) { create(:facility, facility_group: authorized_facility_group) }

      let!(:overdue_patient_in_facility_2) do
        patient = create(:patient, full_name: "patient_3", registration_facility: facility_2)
        create(:appointment, :overdue, facility: facility_2, patient: patient, scheduled_date: 5.days.ago)
        create(:blood_pressure, :hypertensive, facility: facility_2, patient: patient)
        patient
      end

      let!(:unauthorized_facility_group) { create(:facility_group) }

      let!(:unauthorized_facility) { create(:facility, facility_group: unauthorized_facility_group) }

      let!(:overdue_patient_in_unauthorized_facility) do
        patient = create(:patient, full_name: "patient_4", registration_facility: unauthorized_facility)
        create(:appointment, :overdue, facility: unauthorized_facility, patient: patient)
        patient
      end

      before do
        visit appointments_path
      end

      it "shows all overdue patients" do
        expect(page).to have_content(overdue_patient_in_facility_1.full_name)
        expect(page).to have_content(overdue_patient_in_facility_2.full_name)
        expect(page).to have_content("Registered on")
        expect(page).not_to have_content(non_overdue_patient_in_facility_1.full_name)
        expect(page).not_to have_content(overdue_patient_in_unauthorized_facility.full_name)
        expect(page).to have_content(/select a facility/i)
        expect(page).not_to have_selector("a", text: "Download Overdue List")
      end
    end
  end
end
