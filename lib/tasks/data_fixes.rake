require 'tasks/scripts/move_user_recorded_data_to_registration_facility'
require 'tasks/scripts/clean_biswanath_dupes'

namespace :data_fixes do
  desc 'Move all data recorded by a user from a source facility to a destination facility'
  task :move_user_data_from_source_to_destination_facility, [:user_id, :source_facility_id, :destination_facility_id] => :environment do |_t, args|
    user = User.find(args.user_id)
    source_facility = Facility.find(args.source_facility_id)
    destination_facility = Facility.find(args.destination_facility_id)
    service = MoveUserRecordedDataToRegistrationFacility.new(user, source_facility, destination_facility)
    patient_count = service.fix_patient_data
    bp_count = service.fix_blood_pressure_data
    bs_count = service.fix_blood_sugar_data
    appointment_count = service.fix_appointment_data
    prescription_drug_count = service.fix_prescription_drug_data
    puts "[DATA FIXED]"\
         "user: #{user.full_name}, source: #{source_facility.name}, destination: #{destination_facility.name}, "\
         "patients: #{patient_count}, BPs: #{bp_count}, blood sugars: #{bs_count}, "\
         "appointments: #{appointment_count}, prescriptions: #{prescription_drug_count}"
  end

  desc 'Clean up Biswanath duplicate patients - May 2020'
  task :clean_biswanath_dupes => :environment do
    CleanBiswanathDupes.call
  end

  desc 'Clean up Biswanath duplicate patients (dryrun)- May 2020'
  task :clean_biswanath_dupes_dryrun => :environment do
    CleanBiswanathDupes.call(dryrun: true)
  end
end
