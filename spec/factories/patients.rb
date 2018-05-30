FactoryBot.define do
  factory :patient do
    common_names = { 'female'      => %w[anjali divya ishita priya priyanka riya shreya tanvi tanya vani],
                     'male'        => %w[abhishek adityaamit ankit deepak mahesh rahul rohit shyam yash],
                     'transgender' => %w[bharathi madhu bharathi manabi anjum vani riya shreya kiran amit] }

    transient do
      has_date_of_birth? { [true, false].sample }
    end

    id { SecureRandom.uuid }
    gender { Patient::GENDERS.sample }
    full_name { common_names[gender].sample + " " + common_names[gender].sample }
    status { Patient::STATUSES.sample }
    date_of_birth { Date.today if has_date_of_birth? }
    age { rand(18..100) unless has_date_of_birth? }
    age_updated_at { Time.now - rand(10).days if age.present? }
    device_created_at { Time.now }
    device_updated_at { Time.now }
    association :address, strategy: :build
    phone_numbers { build_list(:patient_phone_number, rand(1..3), patient_id: id) }
  end
end

def with_payload_keys(attributes)
  key_mapping = {
    'device_created_at' => 'created_at',
    'device_updated_at' => 'updated_at'
  }.with_indifferent_access

  attributes.transform_keys { |key| key_mapping[key] || key }
end

def build_patient_payload(patient = FactoryBot.build(:patient))
  with_payload_keys(patient.attributes)
    .except('address_id')
    .merge(
      'address'       => with_payload_keys(patient.address.attributes),
      'phone_numbers' => patient.phone_numbers.map { |phno| with_payload_keys(phno.attributes).except('patient_id') }
    )
end

def build_invalid_patient_payload
  patient                          = build_patient_payload
  patient['created_at']            = nil
  patient['address']['created_at'] = nil
  patient['phone_numbers'].each do |phone_number|
    phone_number.merge!('created_at' => nil)
  end
  patient
end

def updated_patient_payload(existing_patient)
  phone_number = existing_patient.phone_numbers.sample || FactoryBot.build(:patient_phone_number, patient: existing_patient)
  update_time  = 10.days.from_now
  build_patient_payload(existing_patient).deep_merge(
    'full_name'     => Faker::Name.name,
    'updated_at'    => update_time,
    'address'       => { 'updated_at'     => update_time,
                         'street_address' => Faker::Address.street_address },
    'phone_numbers' => [with_payload_keys(phone_number.attributes).merge(
      'updated_at' => update_time,
      'number'     => Faker::PhoneNumber.phone_number)]
  )
end
