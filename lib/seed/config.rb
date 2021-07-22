module Seed
  class Config
    # By default the fast seed config will be used for dev. You can override this via the ENV var SEED_TYPE
    def initialize
      @type = ENV["SEED_TYPE"] ||
        case SimpleServer.env
        when "android_review"
          "empty"
        when "development", "review"
          "small"
        when "test"
          "test"
        when "sandbox", "demo"
          "large"
        else
          raise ArgumentError, "Invalid SimpleServer.env #{SimpleServer.env} for Seed configuration"
        end
      Dotenv.load!(".env.seed.#{type}")
    end

    def stdout
      @stdout ||= if SimpleServer.env == "test"
        StringIO.new
      else
        $stdout
      end
    end

    attr_reader :type

    # This is the overall percentage to scale the dataset size by - a factor of 1.0
    # will use the values in the configured dataset as is.
    def scale_factor
      Float(ENV["SCALE_FACTOR"] || 1.0)
    end

    # In test mode, randomness is turned off so that tests can make deterministic assertions on results.
    def test_mode
      ENV["SEED_TEST_MODE"] || false
    end
    alias_method :test_mode?, :test_mode

    def rand_or_max(range, scale: false)
      return range.end if test_mode?
      if scale
        scaled_range = Range.new(range.begin, (range.end * scale_factor))
        rand(scaled_range)
      else
        rand(range)
      end
    end

    def admin_password
      ENV["SEED_ADMIN_PASSWORD"]
    end

    def seed_generated_active_user_role
      ENV["SEED_GENERATED_ACTIVE_USER_ROLE"]
    end

    def number_of_states
      Integer(ENV["NUMBER_OF_STATES"])
    end

    def number_of_facility_groups
      Integer(ENV["NUMBER_OF_FACILITY_GROUPS"])
    end

    def max_number_of_users_per_facility
      Integer(ENV["MAX_NUMBER_OF_USERS_PER_FACILITY"])
    end

    def max_number_of_facilities_per_facility_group
      Integer(ENV["MAX_NUMBER_OF_FACILITIES_PER_FACILITY_GROUP"])
    end

    def max_patients_to_create
      {
        community: Integer(ENV["MAX_PATIENTS_TO_CREATE_COMMUNITY"]),
        small: Integer(ENV["MAX_PATIENTS_TO_CREATE_SMALL"]),
        medium: Integer(ENV["MAX_PATIENTS_TO_CREATE_MEDIUM"]),
        large: Integer(ENV["MAX_PATIENTS_TO_CREATE_LARGE"])
      }
    end

    def max_bps_to_create
      Integer(ENV["MAX_BPS_TO_CREATE"])
    end
  end
end
