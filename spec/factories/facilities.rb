FactoryBot.define do
  factory :facility do
    id { SecureRandom.uuid }
    sequence(:name) { |n| "Facility #{n}" }
    sequence(:street_address) { |n| "#{n} Gandhi Road" }
    sequence(:village_or_colony) { |n| "Colony #{n}" }
    district { facility_group.name }
    state { facility_group.state }
    country { Region.root.name }
    pin { "123456" }
    zone { Faker::Address.community }
    facility_type { "PHC" }
    facility_size { Facility.facility_sizes[:small] }
    facility_group { create(:facility_group) }
    enable_diabetes_management { [true, false].sample }
    enable_teleconsultation { false }
    monthly_estimated_opd_load { 300 }

    trait :with_teleconsultation do
      enable_teleconsultation { true }
      teleconsultation_medical_officers { [create(:user)] }
    end

    trait :seed do
      sequence(:name) { |n| "#{facility_type} #{village_or_colony} #{n}" }
      street_address { Faker::Address.street_address }
      village_or_colony { Seed::FakeNames.instance.village }
      district { Faker::Address.district }
      state { Faker::Address.state }
      country { "India" }
      pin { Faker::Address.zip_code }
      zone { Faker::Address.block }
      facility_type { "PHC" }
    end

    transient do
      create_parent_region { true }
    end

    before(:create) do |facility, options|
      if options.create_parent_region
        facility.facility_group.region.block_regions.find_by(name: facility.zone) ||
          create(:region, :block, name: facility.zone, reparent_to: facility.facility_group.region)
      end
    end

    trait :without_parent_region do
      create_parent_region { false }
    end
  end
end
