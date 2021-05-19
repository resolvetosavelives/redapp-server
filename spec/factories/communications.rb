FactoryBot.define do
  factory :communication do
    id { SecureRandom.uuid }
    notification { nil }
    user
    communication_type { :manual_call }
    device_created_at { Time.current }
    device_updated_at { Time.current }

    trait(:missed_visit_sms_reminder) { communication_type { :missed_visit_sms_reminder } }
    trait(:missed_visit_whatsapp_reminder) { communication_type { :missed_visit_whatsapp_reminder } }
    trait(:with_appointment) { appointment { create(:appointment) } }
  end
end

def build_communication_payload(communication = FactoryBot.build(:communication))
  communication.attributes.merge(communication_result: "successful").with_payload_keys
end

def build_invalid_communication_payload
  build_communication_payload.merge(
    "communication_type" => nil,
    "communication_result" => "foo"
  )
end

def updated_communication_payload(existing_communication)
  update_time = 10.days.from_now
  updated_result = Communication::COMMUNICATION_RESULTS.keys
    .reject { |result| result == existing_communication.communication_result.to_s }
    .sample
  build_communication_payload(existing_communication).merge(
    "updated_at" => update_time,
    "communication_result" => updated_result
  )
end
