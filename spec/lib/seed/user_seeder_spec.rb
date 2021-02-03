require "rails_helper"

RSpec.describe Seed::UserSeeder do
  let(:config) { Seed::Config.new }

  it "creates standard user types" do
    create_list(:facility_group, 2)
    Seed::UserSeeder.call(config: config)

    power_user = User.search_by_email("power_user@simple.org").first
    expect(power_user).to_not be_nil
    expect(power_user.access_level).to eq("power_user")

    cvho = User.search_by_email("cvho@simple.org").first
    expect(cvho).to_not be_nil
    expect(cvho.access_level).to eq("manager")
    expect(cvho.accesses.count).to eq(2)
  end

  it "creates Users for each facility" do
    create_list(:facility, 5, facility_size: "community")

    facility_count = Facility.count
    expected_dashboard_users = 2
    expected_users_per_facility = config.max_number_of_users_per_facility
    expected_phone_sync_users = expected_users_per_facility * Facility.count
    expected_total_users = expected_dashboard_users + expected_phone_sync_users
    expect {
      Seed::UserSeeder.call(config: config)
    }.to change { User.count }.by(expected_total_users)
      .and change { PhoneNumberAuthentication.count }.by(expected_phone_sync_users)
    User.where(role: config.seed_generated_active_user_role).all.each do |user|
      expect(user.phone_number_authentication).to_not be_nil
    end
    Facility.all.each do |facility|
      expect(facility.users.size).to eq(expected_users_per_facility)
    end
  end
end
