require 'yaml'
require 'factory_bot_rails'
require 'faker'
require 'timecop'

def common_names
  {
    'english' =>
      { 'female' => %w[Anjali Divya Ishita Priya Priyanka Riya Shreya Tanvi Tanya Vani].take(3).take(3),
        'male' => %w[Abhishek Aditya Amit Ankit Deepak Mahesh Rahul Rohit Shyam Yash].take(3),
        'transgender' => %w[Bharathi Madhu Bharathi Manabi Anjum Vani Riya Shreya Kiran Amit].take(3),
        'last_name' => %w[Lamba Bahl Sodhi Sardana Puri Chhabra Khanna Malhotra Mehra Garewal Dhillon].take(3)
      },

    'punjabi' =>
      {
        'female' => %w[ਅੰਜਲੀ ਦਿਵਿਆ ਇਸ਼ਿਤਾ ਪ੍ਰਿਆ ਪ੍ਰਿਯੰਕਾ ਰਿਯਾ ਸ਼੍ਰੇਯਾ ਟਾਂਵੀ ਤੰਯਾ ਵਨੀ].take(3),
        'male' => %w[ਅਭਿਸ਼ੇਕ ਆਦਿਤਿਆ ਅਮਿਤ ਅੰਕਿਤ ਦੀਪਕ ਮਹੇਸ਼ ਰਾਹੁਲ ਰੋਹਿਤ ਸ਼ਿਆਮ ਯਸ਼ ].take(3),
        'transgender' => %w[ਭਰਾਠੀ ਮਧੂ ਮਾਨਬੀ ਅੰਜੁਮ ਵਨੀ ਰਿਯਾ ਸ਼੍ਰੇਯਾ ਕਿਰਨ ਅਮਿਤ].take(3),
        'last_name' => %w[ਲੰਬਾ ਬਹਿਲ ਸੋਢੀ ਸਰਦਾਨਾ ਪੂਰੀ ਛਾਬੜਾ ਖੰਨਾ ਮਲਹੋਤਰਾ ਮੇਹਰ ਗਰੇਵਾਲ ਢਿੱਲੋਂ].take(3)
      }
  }
end

def common_addresses
  {
    'bathinda' => {
      'english' => {
        street_name: ['Bhagat singh colony', 'Gandhi Basti', 'NFL Colony', 'Farid Nagari'],
        village_or_colony: %w[Bathinda Bhagwangarh Dannewala Nandgarh Nathana],
      },
      'punjabi' => {
        street_name: ['ਭਗਤ ਸਿੰਘ ਕਾਲੋਨੀ', 'ਗਾਂਧੀ ਬਸਤੀ', 'ਨਫ਼ਲ ਕਾਲੋਨੀ', 'ਫਰੀਦ ਨਗਰੀ'],
        village_or_colony: %w[ਬਠਿੰਡਾ ਭਗਵੰਗੜ੍ਹ ਡੰਨਵਾਲਾ ਨੰਦਗੜ੍ਹ ਨਥਾਣਾ],
      }
    },
    'mansa' => {
      'english' => {
        street_name: ['Bathinda Road', 'Bus Stand Rd', 'Hirke Road', 'Makhewala Jhanduke Road'],
        village_or_colony: ['Bhikhi', 'Budhlada', 'Hirke', 'Jhanduke', 'Mansa', 'Bareta', 'Bhaini Bagha', 'Sadulgarh', 'Sardulewala']
      },
      'punjabi' => {
        street_name: ['ਬਠਿੰਡਾ ਰੋਡ', 'ਬੱਸ ਸਟੈਂਡ ਰੱਦ', 'ਹੀਰਕੇ ਰੋਡ', 'ਮਖੇਵਾਲਾ ਝੰਡੂਕੇ ਰੋਡ'],
        village_or_colony: ['ਭੀਖੀ', 'ਬੁਢਲਾਡਾ', 'ਹੀਰਕੇ', 'ਝੰਡੂਕੇ', 'ਮਾਨਸਾ', 'ਬਰੇਟਾ', 'ਭੈਣੀ ਬਾਘਾ', 'ਸਾਦੁਲਗੜ੍ਹ', 'ਸਰਦੁਲੇਵਾਲਾ']
      }
    }
  }
end

def random_date(from = 0.0, to = Time.now)
  Time.at(from + rand * (to.to_f - from.to_f))
end

def generate_phone_number
  digits = (0..9).to_a
  phone_number = ''
  10.times do
    phone_number += digits.sample.to_s
  end
  phone_number
end

def create_random_patient_phone_number(patient_id)
  patient_phone_number = {
    id: SecureRandom.uuid,
    number: generate_phone_number,
    phone_type: PatientPhoneNumber::PHONE_TYPE.sample,
    active: true,
    patient_id: patient_id,
    device_created_at: Time.now,
    device_updated_at: Time.now
  }
  PatientPhoneNumber.create(patient_phone_number)
end

def create_random_address(district, language)
  addresses = common_addresses[district][language]
  address = {
    id: SecureRandom.uuid,
    street_address: "# #{rand(100)}, #{addresses[:street_name].sample}",
    village_or_colony: addresses[:village_or_colony].sample,
    district: district,
    state: language == 'punjabi' ? 'ਪੰਜਾਬ' : 'Punjab',
    country: language == 'punjabi' ? 'ਇੰਡੀਆ' : 'India',
    pin: district == 'bathinda' ? "1510#{rand(100)}" : "1515#{rand(100)}",
    device_created_at: Time.now,
    device_updated_at: Time.now
  }
  Address.create(address)
end

def create_random_patient(address_id, language)
  has_age = [true, false].sample
  gender = Patient::GENDERS.sample
  full_name = "#{common_names[language][gender].sample} #{common_names[language]['last_name'].sample}"
  patient = {
    id: SecureRandom.uuid,
    gender: gender,
    full_name: full_name,
    status: 'active',
    age: has_age ? rand(18..100) : nil,
    age_updated_at: has_age ? Time.now : nil,
    address_id: address_id,
    date_of_birth: !has_age ? random_date : nil,
    device_created_at: Time.now,
    device_updated_at: Time.now,
    test_data: true
  }

  Patient.create(patient)
end

def create_blood_pressure(bp_type, creation_date, patient)
  FactoryBot.create(:blood_pressure, bp_type,
                    patient: patient,
                    facility: patient.registration_facility,
                    user: patient.registration_user,
                    created_at: creation_date,
                    updated_at: creation_date,
                    recorded_at: creation_date,
                    device_updated_at: creation_date,
                    device_created_at: creation_date)
end

namespace :generate do
  desc 'Generate test patients for user tests'
  # Example: rake "generate:random_patients_for_user_tests[20]"
  task :random_patients_for_user_tests, [:number_of_patients_to_generate] => :environment do |_t, args|
    max_patient_phone_numbers = 1
    number_of_patients_to_generate = args.number_of_patients_to_generate.to_i

    number_of_patients_to_generate.times do
      district = common_addresses.keys.sample
      language = common_addresses[district].keys.sample
      address = create_random_address(district, language)
      patient = create_random_patient(address.id, language)
      rand(1..max_patient_phone_numbers).times do
        create_random_patient_phone_number(patient.id)
      end
    end
  end

  task :patients_for_user_tests => :environment do
    test_patient_data = [
      { full_name: "Govind Lamba", age: 57, language: 'english' },
      { full_name: "Govind Lamba", age: 41, language: 'english' },
      { full_name: "Govind Lamba", age: 79, language: 'english' },
      { full_name: "Govind Lamba", age: 33, language: 'english' },
      { full_name: "Govind Lamba", age: 30, language: 'english' },
      { full_name: "Govind Bahl", age: 51, language: 'english' },
      { full_name: "Govind Bahl", age: 48, language: 'english' },
      { full_name: "Govind Bahl", age: 21, language: 'english' },
      { full_name: "Govind Bahl", age: 54, language: 'english' },
      { full_name: "Govind Bahl", age: 77, language: 'english' },
      { full_name: "Govind Sodhi", age: 89, language: 'english' },
      { full_name: "Govind Sodhi", age: 36, language: 'english' },
      { full_name: "Govind Sodhi", age: 82, language: 'english' },
      { full_name: "Govind Sodhi", age: 64, language: 'english' },
      { full_name: "Govind Sodhi", age: 79, language: 'english' },
      { full_name: "Harjeet Lamba", age: 54, language: 'english' },
      { full_name: "Harjeet Lamba", age: 67, language: 'english' },
      { full_name: "Harjeet Lamba", age: 40, language: 'english' },
      { full_name: "Harjeet Lamba", age: 29, language: 'english' },
      { full_name: "Harjeet Lamba", age: 67, language: 'english' },
      { full_name: "Harjeet Bahl", age: 66, language: 'english' },
      { full_name: "Harjeet Bahl", age: 22, language: 'english' },
      { full_name: "Harjeet Bahl", age: 37, language: 'english' },
      { full_name: "Harjeet Bahl", age: 52, language: 'english' },
      { full_name: "Harjeet Bahl", age: 31, language: 'english' },
      { full_name: "Harjeet Sodhi", age: 30, language: 'english' },
      { full_name: "Harjeet Sodhi", age: 44, language: 'english' },
      { full_name: "Harjeet Sodhi", age: 68, language: 'english' },
      { full_name: "Harjeet Sodhi", age: 51, language: 'english' },
      { full_name: "Harjeet Sodhi", age: 55, language: 'english' },
      { full_name: "ਗੋਵਿੰਦ ਲੰਬਾ", age: 83, language: 'punjabi' },
      { full_name: "ਗੋਵਿੰਦ ਲੰਬਾ", age: 52, language: 'punjabi' },
      { full_name: "ਗੋਵਿੰਦ ਲੰਬਾ", age: 69, language: 'punjabi' },
      { full_name: "ਗੋਵਿੰਦ ਲੰਬਾ", age: 24, language: 'punjabi' },
      { full_name: "ਗੋਵਿੰਦ ਲੰਬਾ", age: 44, language: 'punjabi' },
      { full_name: "ਗੋਵਿੰਦ ਬਹਿਲ", age: 84, language: 'punjabi' },
      { full_name: "ਗੋਵਿੰਦ ਬਹਿਲ", age: 76, language: 'punjabi' },
      { full_name: "ਗੋਵਿੰਦ ਬਹਿਲ", age: 85, language: 'punjabi' },
      { full_name: "ਗੋਵਿੰਦ ਬਹਿਲ", age: 39, language: 'punjabi' },
      { full_name: "ਗੋਵਿੰਦ ਬਹਿਲ", age: 81, language: 'punjabi' },
      { full_name: "ਗੋਵਿੰਦ ਸੋਢੀ", age: 22, language: 'punjabi' },
      { full_name: "ਗੋਵਿੰਦ ਸੋਢੀ", age: 90, language: 'punjabi' },
      { full_name: "ਗੋਵਿੰਦ ਸੋਢੀ", age: 44, language: 'punjabi' },
      { full_name: "ਗੋਵਿੰਦ ਸੋਢੀ", age: 22, language: 'punjabi' },
      { full_name: "ਗੋਵਿੰਦ ਸੋਢੀ", age: 23, language: 'punjabi' },
      { full_name: "ਹਰਜੀਤ ਲੰਬਾ", age: 38, language: 'punjabi' },
      { full_name: "ਹਰਜੀਤ ਲੰਬਾ", age: 30, language: 'punjabi' },
      { full_name: "ਹਰਜੀਤ ਲੰਬਾ", age: 43, language: 'punjabi' },
      { full_name: "ਹਰਜੀਤ ਲੰਬਾ", age: 42, language: 'punjabi' },
      { full_name: "ਹਰਜੀਤ ਲੰਬਾ", age: 90, language: 'punjabi' },
      { full_name: "ਹਰਜੀਤ ਬਹਿਲ", age: 56, language: 'punjabi' },
      { full_name: "ਹਰਜੀਤ ਬਹਿਲ", age: 34, language: 'punjabi' },
      { full_name: "ਹਰਜੀਤ ਬਹਿਲ", age: 31, language: 'punjabi' },
      { full_name: "ਹਰਜੀਤ ਬਹਿਲ", age: 69, language: 'punjabi' },
      { full_name: "ਹਰਜੀਤ ਬਹਿਲ", age: 57, language: 'punjabi' },
      { full_name: "ਹਰਜੀਤ ਸੋਢੀ", age: 30, language: 'punjabi' },
      { full_name: "ਹਰਜੀਤ ਸੋਢੀ", age: 81, language: 'punjabi' },
      { full_name: "ਹਰਜੀਤ ਸੋਢੀ", age: 29, language: 'punjabi' },
      { full_name: "ਹਰਜੀਤ ਸੋਢੀ", age: 66, language: 'punjabi' },
      { full_name: "ਹਰਜੀਤ ਸੋਢੀ", age: 57, language: 'punjabi' }
    ]

    test_patient_data.each do |patient_data|
      patient = Patient.create(
        id: SecureRandom.uuid,
        full_name: patient_data[:full_name],
        age: patient_data[:age],
        gender: 'male',
        status: 'active',
        age_updated_at: Time.now,
        address_id: create_random_address('bathinda', patient_data[:language]).id,
        date_of_birth: nil,
        device_created_at: Time.now,
        device_updated_at: Time.now,
        test_data: true)
      create_random_patient_phone_number(patient.id)
    end
  end

  namespace :seed do
    task :generate_data, [:number_of_months] => :environment do |_t, args|
      number_of_months = args.fetch(:number_of_months) { 3 }.to_i
      environment = ENV.fetch('SIMPLE_SERVER_ENV') { 'development' }
      config = YAML.load_file('config/seed.yml').dig(environment)

      Rails.logger.info("Creating seed data for environment \"#{environment}\" for a period of #{number_of_months} month(s)")

      if environment == 'development'
        Rails.logger.info("Detected development environment. Creating organization hierarchy first...")

        truncate_db
        Rails.logger.info("Truncated database")

        FactoryBot.create(:admin, email: "admin@simple.org", password: 123456, role: 'owner')
        Rails.logger.info("Created login admin (admin@simple.org/123456)")

        create_protocols_and_protocol_drugs(config)
        create_organizations(number_of_months.months.ago, config)

        number_of_months.downto(1) do |month_number|
          creation_date = month_number.months.ago.beginning_of_month

          Organization.all.each do |organization|
            create_organization_patient_records(organization, creation_date, config)
          end
        end
      end

      create_seed_data(number_of_months, config)

      Rails.logger.info("Finished generating seed data for #{ENV.fetch('SIMPLE_SERVER_ENV')}")
    end

    def create_seed_data(number_of_months, config)
      number_of_months.downto(1) do |month_number|
        creation_date = month_number.months.ago.beginning_of_month

        Organization.all.flat_map(&:users).each do |user|
          create_patients(user, creation_date, config)
        end
      end
    end

    def create_protocols_and_protocol_drugs(config)
      config.fetch('protocols').times do
        protocol = FactoryBot.create(:protocol)

        config.fetch('protocol_drugs').times do
          FactoryBot.create(:protocol_drug, protocol: protocol)
        end
      end

      Rails.logger.info("Created protocols and protocol drugs")
    end

    def create_organization_patient_records(organization, date, config)
      facility_groups = organization.facility_groups

      is_hypertensive = get_traits_for_property(config, 'patients').include?('hypertensive')

      facility_groups.flat_map(&:facilities).flat_map(&:registered_patients).each do |patient|
        create_blood_pressures(patient, date, config, is_hypertensive)
      end

      number_of_patients = config.dig('patients', 'count')
      facility_groups.flat_map(&:users).each do |user|
        number_of_patients.times do
          create_patients(user, date, config)
        end
      end
    end

    def create_patients(user, creation_date, config)
      number_of_patients = config.dig('patients', 'count')
      Timecop.travel(creation_date) do
        Timecop.scale(1.week) do
          number_of_patients.times do
            time = Time.now
            patient = FactoryBot.create(:patient, registration_facility: user.registration_facility,
                                        registration_user: user,
                                        created_at: time,
                                        updated_at: time,
                                        age_updated_at: time,
                                        device_created_at: time,
                                        device_updated_at: time)

            if patient.age.nil?
              patient.age = rand(18..100)
              patient.date_of_birth = nil
              patient.save
            end

            patient_traits = get_traits_for_property(config, 'patients')
            is_overdue = patient_traits.include?('overdue')
            is_hypertensive = patient_traits.include?('hypertensive')

            create_medical_history(patient, time, config)
            create_prescription_drugs(patient, time, config)
            create_blood_pressures(patient, time, config, is_hypertensive)
            create_appointments(patient, time, config, is_overdue)

            create_call_logs(patient, time)
            create_exotel_phone_number_detail(patient, time)
          end
        end
      end
      Rails.logger.info("Created patients for date #{creation_date}")
    end

    def create_medical_history(patient, creation_date, config)
      number_of_medical_histories = config.dig('patients', 'medical_histories')
      Timecop.travel(creation_date) do
        Timecop.scale(1.week) do
          number_of_medical_histories.times do
            time = Time.now

            FactoryBot.create(:medical_history, :unknown,
                              patient: patient,
                              created_at: time,
                              updated_at: time,
                              device_created_at: time,
                              device_updated_at: time)

            FactoryBot.create(:medical_history, :prior_risk_history,
                              patient: patient,
                              created_at: time,
                              updated_at: time,
                              device_created_at: time,
                              device_updated_at: time)
          end
        end
      end

      Rails.logger.info("Created medical histories for date #{creation_date}")
    end

    def create_prescription_drugs(patient, creation_date, config)
      number_of_prescription_drugs = config.dig('patients', 'prescription_drugs')
      Timecop.travel(creation_date) do
        Timecop.scale(1.week) do
          number_of_prescription_drugs.times do
            time = Time.now
            FactoryBot.create(:prescription_drug, patient: patient,
                              facility: patient.registration_facility,
                              created_at: time,
                              updated_at: time,
                              device_created_at: time,
                              device_updated_at: time)
          end
        end
      end
      Rails.logger.info("Created Prescription Drugs for date #{creation_date}")
    end

    def create_blood_pressures(patient, creation_date, config, is_hypertensive)
      number_of_blood_pressures = config.dig('patients', 'blood_pressures')
      Timecop.travel(creation_date) do
        Timecop.scale(1.week) do
          number_of_blood_pressures.times do
            create_blood_pressure(:under_control, Time.now, patient)

            [:high, :very_high, :critical].each do |bp_type|
              create_blood_pressure(bp_type, Time.now, patient) if is_hypertensive
            end
          end
        end
      end

      Rails.logger.info("Created blood pressures for date #{creation_date}")
    end

    def create_appointments(patient, creation_date, config, is_overdue)
      number_of_appointments = config.dig('patients', 'appointments')
      Timecop.travel(creation_date) do
        Timecop.scale(1.week) do
          number_of_appointments.times do
            time = Time.now
            future_date = Timecop.return { 30.days.from_now }
            FactoryBot.create(:appointment,
                              patient: patient,
                              facility: patient.registration_facility,
                              created_at: time,
                              updated_at: time,
                              scheduled_date: future_date,
                              device_created_at: time,
                              device_updated_at: time)
            time_2 = Time.now
            FactoryBot.create(:appointment, :overdue,
                              patient: patient,
                              facility: patient.registration_facility,
                              created_at: time_2,
                              updated_at: time_2,
                              device_created_at: time_2,
                              device_updated_at: time_2)
          end
        end
      end
      Rails.logger.info("Created appointments for date #{creation_date}")
    end

    def create_call_logs(patient, creation_date)
      caller_phone_number = patient.registration_user.phone_number_authentications.first.phone_number
      callee_phone_number = patient.phone_numbers.first.number

      Timecop.travel(creation_date) do
        FactoryBot.create(:call_log,
                          session_id: SecureRandom.uuid.remove('-'),
                          caller_phone_number: caller_phone_number,
                          callee_phone_number: callee_phone_number,
                          created_at: Time.now,
                          updated_at: Time.now,
                          duration: rand(60) + 1)
      end
      Rails.logger.info("Created call logs for date #{creation_date}")
    end

    def create_exotel_phone_number_detail(patient, creation_date)
      Timecop.travel(creation_date) do
        whitelist_status = ExotelPhoneNumberDetail.whitelist_statuses.to_a.sample.first
        FactoryBot.create(:exotel_phone_number_detail, whitelist_status: whitelist_status,
                          patient_phone_number: patient.phone_numbers.first,
                          created_at: Time.now,
                          updated_at: Time.now)
      end

      Rails.logger.info("Created exotel phone number details for date #{creation_date}")
    end

    def get_traits_for_property(config_hash, property)
      config_hash.dig(property, 'traits')
    end

    def truncate_db
      conn = ActiveRecord::Base.connection
      tables = conn.execute("
      SELECT tablename
      FROM pg_catalog.pg_tables
      WHERE schemaname = 'public' AND
            tablename NOT IN ('schema_migrations', 'ar_internal_metadata')
    ")

      tables.each do |t|
        tablename = t["tablename"]
        conn.execute("TRUNCATE #{tablename} CASCADE")
      end
    end

    def dev_organizations
      [
        {
          name: "IHCI",
          facility_groups: [
            {
              name: "Bathinda and Mansa",
              facilities: [
                { name: "CHC Buccho", district: "Bathinda", state: "Punjab" },
                { name: "CHC Meheraj", district: "Bathinda", state: "Punjab" },
                { name: "District Hospital Bathinda", district: "Bathinda", state: "Punjab" },
                { name: "PHC Joga", district: "Mansa", state: "Punjab" }
              ]
            },
            {
              name: "Gurdaspur",
              facilities: [
                { name: "CHC Kalanaur", district: "Gurdaspur", state: "Punjab" },
                { name: "PHC Bhumbli", district: "Gurdaspur", state: "Punjab" },
                { name: "SDH Batala", district: "Gurdaspur", state: "Punjab" }
              ]
            },
            {
              name: "Bhandara",
              facilities: [
                { name: "CH Bhandara", district: "Bhandara", state: "Maharashtra" },
                { name: "HWC Bagheda", district: "Bhandara", state: "Maharashtra" },
                { name: "HWC Chikhali", district: "Bhandara", state: "Maharashtra" }
              ]
            },
            {
              name: "Hoshiarpur",
              facilities: [
                { name: "CHC Bhol Kalota", district: "Hoshiarpur", state: "Punjab" },
                { name: "PHC Hajipur", district: "Hoshiarpur", state: "Punjab" },
                { name: "SDH Mukerian", district: "Hoshiarpur", state: "Punjab" }
              ]
            },
            {
              name: "Satara",
              facilities: [
                { name: "CHC Satara", district: "Satara", state: "Maharashtra" },
                { name: "PHC Girvi", district: "Satara", state: "Maharashtra" },
                { name: "SDH Indoli", district: "Satara", state: "Maharashtra" }
              ]
            },
          ]
        },
        {
          name: "PATH",
          facility_groups: [
            {
              name: "Amir Singh Facility Group",
              facilities: [
                { name: "Amir Singh", district: "Mumbai", state: "Maharashtra" }
              ]
            },
            {
              name: "Dr. Anwar Facility Group",
              facilities: [
                { name: "Dr. Anwar", district: "Mumbai", state: "Maharashtra" }
              ]
            },
            {
              name: "Dr. Abhishek Tripathi",
              facilities: [
                { name: "Dr. Abhishek Tripathi", district: "N Ward", state: "Maharashtra" }
              ]
            },
            {
              name: "Dr. Shailaja Thorat",
              facilities: [
                { name: "Dr. Shailaja Thorat", district: "Ghatkopar E", state: "Maharashtra" }
              ]
            },
            {
              name: "Dr. Ayazuddin Farooqui",
              facilities: [
                { name: "Dr. Ayazuddin Farooqui", district: "Dharavi", state: "Maharashtra" }
              ]
            }
          ]
        }
      ]
    end

    def create_users(facilities, creation_date, config)
      Timecop.travel(creation_date) do
        Timecop.scale(1.day) do
          facilities.each do |f|
            config.dig('users', 'count').times do
              time = Time.now
              FactoryBot.create(:user, registration_facility: f, created_at: time, updated_at: time)

              create_sync_requested_user(f, Time.now)
              create_sync_denied_user(f, Time.now)
            end
          end
        end
      end
      Rails.logger.info("Created users for date #{creation_date}")
    end

    def create_sync_requested_user(facility, creation_date)
      user = FactoryBot.create(:user,
                               registration_facility: facility,
                               created_at: creation_date,
                               updated_at: creation_date,
                               device_created_at: creation_date,
                               device_updated_at: creation_date)
      user.sync_approval_status = 'requested'
      user.sync_approval_status_reason = ['New Registration', 'Reset PIN'].sample

      user.save
    end

    def create_sync_denied_user(facility, creation_date)
      user = FactoryBot.create(:user,
                               registration_facility: facility,
                               created_at: creation_date,
                               updated_at: creation_date,
                               device_created_at: creation_date,
                               device_updated_at: creation_date)
      user.sync_approval_status = 'denied'
      user.sync_approval_status_reason = 'some random reason'
      user.save
    end


    def create_organizations(creation_date, config)
      dev_organizations.each do |dev_org|
        organization = FactoryBot.create(:organization, name: dev_org[:name],
                                         created_at: creation_date,
                                         updated_at: creation_date)

        create_facility_groups(organization, dev_org[:facility_groups], creation_date, config)
        create_admins(organization)
      end

      Rails.logger.info("Created organizations for date #{creation_date}")
    end

    def create_facility_groups(organization, facility_groups, creation_date, config)
      Timecop.travel(creation_date) do
        Timecop.scale(1.day) do
          facility_groups.each do |fac_group|
            time = Time.now
            facility_group = FactoryBot.create(:facility_group, name: fac_group[:name],
                                               organization: organization,
                                               created_at: time,
                                               updated_at: time)

            facilities = create_and_return_facilities(facility_group, fac_group[:facilities], time)
            create_users(facilities, time, config)
          end
        end
      end

      Rails.logger.info("Created facility groups for date #{creation_date}")
    end

    def create_admins(organization)
      facility_group = organization.facility_groups.first

      FactoryBot.create(:admin, :counsellor, facility_group: facility_group)
      FactoryBot.create(:admin, :analyst, facility_group: facility_group)
      FactoryBot.create(:admin, :supervisor)
      FactoryBot.create(:admin, :organization_owner, organization: organization)

      Rails.logger.info("Created admins for organization #{organization.name}")
    end

    def create_and_return_facilities(facility_group, facilities, creation_date)
      facility_records = []
      Timecop.travel(creation_date) do
        Timecop.scale(1.day) do
          facilities.each do |fac|
            time = Time.now
            facility_records << FactoryBot.create(:facility, facility_group: facility_group,
                                                  name: fac[:name],
                                                  district: fac[:district],
                                                  state: fac[:state],
                                                  created_at: time,
                                                  updated_at: time)
          end
        end
      end
      Rails.logger.info("Created facilities for facility groyp #{facility_group.name} for date #{creation_date}")
      facility_records
    end
  end
end

