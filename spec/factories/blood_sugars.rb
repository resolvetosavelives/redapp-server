FactoryBot.define do
  factory :blood_sugar do
    id { SecureRandom.uuid }
    blood_sugar_type { BloodSugar::blood_sugar_types.keys.sample }
    blood_sugar_value do
      threshold = BloodSugar::THRESHOLDS[:high][blood_sugar_type]
      rand(threshold*0.9..threshold*1.1).round(2)
    end
    device_created_at { Time.current }
    device_updated_at { Time.current }
    recorded_at { device_created_at }
    facility
    user
    patient
  end
end

def build_blood_sugar_payload(blood_sugar = FactoryBot.build(:blood_sugar))
  Api::V3::BloodSugarTransformer.to_response(blood_sugar).with_indifferent_access
end

def build_invalid_blood_sugar_payload
  build_blood_sugar_payload.merge(
    'created_at' => nil,
    'blood_sugar_type' => 'invalid'
  )
end

def updated_blood_sugar_payload(existing_blood_sugar)
  update_time = 10.days.from_now
  build_blood_sugar_payload(existing_blood_sugar).merge(
    'updated_at' => update_time,
    'blood_sugar_value' => rand(80..240)
  )
end
