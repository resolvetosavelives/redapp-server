FactoryBot.define do
  factory :notification do
    id { SecureRandom.uuid }
    remind_on { Date.current + 3.days }
    status { "pending" }
    message { "notifications.set01.basic" }
    association :patient, factory: :patient
    association :experiment, factory: :experiment
    association :reminder_template, factory: :reminder_template
  end
end
