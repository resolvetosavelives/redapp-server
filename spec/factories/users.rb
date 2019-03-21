FactoryBot.define do
  factory :user do
    full_name { Faker::Name.name }
    phone_number { Faker::PhoneNumber.phone_number }
    password { rand(1000..9999).to_s }
    password_confirmation { password }
    device_updated_at { Time.now }
    device_created_at { Time.now }
    sync_approval_status { User.sync_approval_statuses[:allowed] }
    sync_approval_status_reason nil
    facility

    trait :created_on_device do
      id { SecureRandom.uuid }
      password_digest { BCrypt::Password.create(password) }
      password nil
      password_confirmation nil
    end

    trait :sync_allowed do
      sync_approval_status { User.sync_approval_statuses[:allowed] }
    end

    trait :sync_denied do
      sync_approval_status { User.sync_approval_statuses[:denied] }
    end

    trait :sync_requested do
      sync_approval_status { User.sync_approval_statuses[:requested] }
    end

    trait(:with_sanitized_phone_number) do
      phone_number { rand(1e9...1e10).to_i.to_s }
    end

    factory :user_created_on_device, traits: [:created_on_device]
  end
end

def build_user_payload(user = FactoryBot.build(:user_created_on_device))
  user.attributes.with_payload_keys
end

def build_invalid_user_payload
  build_user_payload.merge(
    'created_at' => nil,
    'full_name' => nil
  )
end

def updated_user_payload(existing_user)
  update_time = 10.days.from_now
  build_user_payload(existing_user).merge(
    'updated_at' => update_time,
    'full_name' => Faker::Name.name
  )
end
