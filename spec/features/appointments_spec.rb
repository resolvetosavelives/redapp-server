require 'rails_helper'

RSpec.feature 'Overdue appointments', type: :feature do
  let!(:counsellor) { create(:admin, :counsellor) }

  describe 'index' do
    before { sign_in(counsellor) }

    it 'shows Overdue tab' do
      visit root_path

      expect(page).to have_content('Overdue patients')
    end

    describe 'Overdue patients tab' do
      let!(:authorized_facility_group) { counsellor.facility_groups.first }

      let!(:facility_1) { create(:facility, facility_group: authorized_facility_group) }

      let!(:overdue_patient_in_facility_1) do
        patient = create(:patient, full_name: 'patient_1', registration_facility: facility_1)
        create(:appointment, :overdue, facility: facility_1, patient: patient, scheduled_date: 10.days.ago)
        create(:blood_pressure, :critical, facility: facility_1, patient: patient)
        patient
      end

      let!(:non_overdue_patient_in_facility_1) { create(:patient, full_name: 'patient_2', registration_facility: facility_1) }

      let!(:facility_2) { create(:facility, facility_group: authorized_facility_group) }

      let!(:overdue_patient_in_facility_2) do
        patient = create(:patient, full_name: 'patient_3', registration_facility: facility_2)
        create(:appointment, :overdue, facility: facility_2, patient: patient, scheduled_date: 5.days.ago)
        create(:blood_pressure, :high, facility: facility_2, patient: patient)
        patient
      end

      let!(:unauthorized_facility_group) { create(:facility_group) }

      let!(:unauthorized_facility) { create(:facility, facility_group: unauthorized_facility_group) }

      let!(:overdue_patient_in_unauthorized_facility) do
        patient = create(:patient, full_name: 'patient_4', registration_facility: unauthorized_facility)
        create(:appointment, :overdue, facility: unauthorized_facility, patient: patient)
        patient
      end

      before do
        visit appointments_path
      end

      it 'shows all overdue patients' do
        expect(page).to have_content(overdue_patient_in_facility_1.full_name)
        expect(page).to have_content(overdue_patient_in_facility_2.full_name)
      end

      it 'does not show non-overdue patients' do
        expect(page).not_to have_content(non_overdue_patient_in_facility_1.full_name)
      end

      it 'does not show overdue patients in unauthorized facilities' do
        expect(page).not_to have_content(overdue_patient_in_unauthorized_facility.full_name)
      end

      it 'shows overdue patients ordered by how overdue they are' do
        within('#overdue-patients') do
          first_item = find(:css, 'section:nth-of-type(1)')
          second_item = find(:css, 'section:nth-of-type(2)')

          expect(first_item).to have_content(overdue_patient_in_facility_1.full_name)
          expect(second_item).to have_content(overdue_patient_in_facility_2.full_name)
        end
      end

      it 'sets a call_result, and removes patient from the overdue list' do
        within('#overdue-patients > section:first-of-type') do
          find(:option, 'Dead').click
        end

        page.reset!
        visit appointments_path
        expect(page).not_to have_content(overdue_patient_in_facility_1.full_name)
      end

      it 'allows you to filter by facility' do
        select facility_1.name, from: "facility_id"
        click_button "Filter"

        expect(page).to have_content(overdue_patient_in_facility_1.full_name)
        expect(page).not_to have_content(overdue_patient_in_facility_2.full_name)
      end

      it 'allows you to download the overdue list CSV' do
        binding.pry
        click_link "Download Overdue List"

        headers = [
          "Patient name",
          "Gender",
          "Age",
          "Days overdue",
          "Last BP",
          "Last BP taken at",
          "Last BP date",
          "Risk level",
          "Patient address",
          "Patient village or colony",
          "Patient phone"
        ]
        expect(page).to have_content(headers.to_csv)

        appointment = overdue_patient_in_facility_1.appointments.first

        appointment_line = [
          appointment.patient.full_name,
          appointment.patient.gender.capitalize,
          appointment.patient.current_age,
          appointment.days_overdue,
          appointment.patient.latest_blood_pressure.to_s,
          appointment.patient.latest_blood_pressure.facility.name,
          appointment.patient.latest_blood_pressure.device_created_at.to_date,
          appointment.patient.high_risk? ? "High risk" : nil,
          appointment.patient.address.street_address,
          appointment.patient.address.village_or_colony,
          appointment.patient.phone_numbers.first&.number
        ]
        expect(page).to have_content(appointment_line.to_csv)
      end
    end
  end
end
