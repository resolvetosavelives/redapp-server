require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "factory_bot_rails"
require "faker"
require "timecop"

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }
Dir[Rails.root.join("spec/pages/application_page.rb")].sort.each { |f| require f }
Dir[Rails.root.join("spec/**/shared_examples/**/*.rb")].sort.each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers

  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include Warden::Test::Helpers

  config.before(:all) do
    # create a root region and persist across all tests (the root region is effectively a singleton)
    Region.root || Region.create!(name: "India", region_type: Region.region_types[:root], path: "india")
  end

  def common_org
    @common_org ||= Organization.find_or_create_by!(name: "Common Test Organization")
  end

    def with_reporting_time_zones(&blk)
      reporting_timezone = Period::REPORTING_TIME_ZONE
      Time.use_zone(reporting_timezone) do
        Groupdate.time_zone = reporting_timezone
        blk.call
        Groupdate.time_zone = nil
      end
    end

  config.before(:each) do
    RequestStore.clear!
  end

  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end

  config.after :each do
    Warden.test_reset!
  end
end
