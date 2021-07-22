module Seed
  class ProductionExperimentTestSeeder
    def self.call(user_id:, days_till_appointment: 1)
      ExperimentSeeder.call(experiment_name: "production test", experiment_type: "current_patients")

      now = Time.current
      today = Date.current
      user = User.find(user_id)
      facility = user.registration_facility

      patient = Patient.create!(id: SecureRandom.uuid, full_name: "Hari AB Tester", status: "active", device_created_at: now, device_updated_at: now, registration_user: user)
      patient.phone_numbers.create!(id: SecureRandom.uuid, number: "8675309", phone_type: "mobile", active: true, device_created_at: now, device_updated_at: now)
      Appointment.create!(scheduled_date: today + days_till_appointment, patient: patient, facility: facility, device_created_at: now, device_updated_at: now, appointment_type: "manual")
      patient = Patient.create!(id: SecureRandom.uuid, full_name: "Vikram AB Tester", status: "active", device_created_at: now, device_updated_at: now, registration_user: user)
      patient.phone_numbers.create!(id: SecureRandom.uuid, number: "8675309", phone_type: "mobile", active: true, device_created_at: now, device_updated_at: now)
      Appointment.create!(scheduled_date: today + days_till_appointment, patient: patient, facility: facility, device_created_at: now, device_updated_at: now, appointment_type: "manual")
      patient = Patient.create!(id: SecureRandom.uuid, full_name: "Srihari AB Tester", status: "active", device_created_at: now, device_updated_at: now, registration_user: user)
      patient.phone_numbers.create!(id: SecureRandom.uuid, number: "8675309", phone_type: "mobile", active: true, device_created_at: now, device_updated_at: now)
      Appointment.create!(scheduled_date: today + days_till_appointment, patient: patient, facility: facility, device_created_at: now, device_updated_at: now, appointment_type: "manual")
      patient = Patient.create!(id: SecureRandom.uuid, full_name: "Prabhanshu AB Tester", status: "active", device_created_at: now, device_updated_at: now, registration_user: user)
      patient.phone_numbers.create!(id: SecureRandom.uuid, number: "8675309", phone_type: "mobile", active: true, device_created_at: now, device_updated_at: now)
      Appointment.create!(scheduled_date: today + days_till_appointment, patient: patient, facility: facility, device_created_at: now, device_updated_at: now, appointment_type: "manual")
      patient = Patient.create!(id: SecureRandom.uuid, full_name: "Pragati AB Tester", status: "active", device_created_at: now, device_updated_at: now, registration_user: user)
      patient.phone_numbers.create!(id: SecureRandom.uuid, number: "8675309", phone_type: "mobile", active: true, device_created_at: now, device_updated_at: now)
      Appointment.create!(scheduled_date: today + days_till_appointment, patient: patient, facility: facility, device_created_at: now, device_updated_at: now, appointment_type: "manual")
    end
  end
end
