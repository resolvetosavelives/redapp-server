require_dependency "seed/config"

module Seed
  class FacilitySeeder
    include ConsoleLogger

    FACILITY_SIZE_WEIGHTS = {
      community: 0.50,
      small: 0.30,
      medium: 0.15,
      large: 0.05
    }.freeze

    SIZES_TO_TYPE = {
      large: ["CH", "DH", "Hospital", "RH", "SDH"],
      medium: ["CHC"],
      small: ["MPHC", "PHC", "SAD", "Standalone", "UHC", "UPHC", "USAD"],
      community: ["HWC", "Village"]
    }

    def self.call(*args)
      new(*args).call
    end

    def initialize(config:)
      @counts = {}
      @config = config
      @logger = Rails.logger.child(class: self.class.name)
      announce "Starting #{self.class} with #{config.type} configuration"
    end

    attr_reader :config
    attr_reader :logger

    delegate :scale_factor, :stdout, to: :config

    def call
      Region.root || Region.create!(name: "India", region_type: Region.region_types[:root], path: "india")

      if number_of_facility_groups <= FacilityGroup.count
        announce "Not creating FacilityGroups or Facilities, we already have max # (#{number_of_facility_groups}) of FacilityGroups"
        return
      end

      announce "Creating protocol and protocol drugs..."
      protocol = Seed::ProtocolSeeder.call(config: config)

      announce "Creating #{number_of_facility_groups} FacilityGroups..."

      state_results = create_state_regions
      facility_group_results = create_facility_groups(protocol)
      district_region_results = create_district_regions(state_results, facility_group_results)
      create_block_regions(district_region_results)
      facility_results = create_facilities(facility_group_results)
      create_facility_regions(facility_results)
    end

    def number_of_facility_groups
      config.number_of_facility_groups
    end

    def number_of_states
      config.number_of_states
    end

    def number_of_facilities_per_facility_group
      config.rand_or_max(1..config.max_number_of_facilities_per_facility_group)
    end

    def weighted_facility_size_sample
      FACILITY_SIZE_WEIGHTS.max_by { |_, weight| rand**(1.0 / weight) }.first
    end

    def max_number_of_blocks_per_facility_group
      2
    end

    def organization
      @organization ||= Seed.seed_org
    end

    def create_state_regions
      state_names = Seed::FakeNames.instance.states.sample(number_of_states)
      states = number_of_states.times.each_with_index.map { |i|
        FactoryBot.build(:region, :state, id: nil, name: state_names[i], parent_path: organization.region.path)
      }
      Region.import(states, returning: [:path])
    end

    def create_facility_groups(protocol)
      district_names = Seed::FakeNames.instance.districts.sample(number_of_facility_groups)
      facility_groups = number_of_facility_groups.times.each_with_index.map { |i|
        FactoryBot.build(:facility_group,
          id: nil,
          create_parent_region: false,
          generating_seed_data: true,
          name: district_names[i],
          organization_id: organization.id,
          protocol_id: protocol.id,
          state: nil)
      }
      FacilityGroup.import(facility_groups, returning: [:id, :name], on_duplicate_key_ignore: true)
    end

    def create_district_regions(state_results, facility_group_results)
      district_regions = facility_group_results.results.map { |row|
        facility_group_id, facility_group_name = *row
        attrs = {
          id: nil,
          name: facility_group_name,
          region_type: "district",
          parent_path: state_results.results.sample,
          source_id: facility_group_id,
          source_type: "FacilityGroup"
        }
        FactoryBot.build(:region, attrs)
      }
      Region.import(district_regions, returning: [:id, :name, :path])
    end

    def create_block_regions(district_region_results)
      # Eagerly fetch block names to avoid duplicates
      block_count = district_region_results.ids.size * max_number_of_blocks_per_facility_group
      block_names = Seed::FakeNames.instance.blocks.sample(block_count)

      block_counter = 0
      block_regions = district_region_results.results.flat_map { |row|
        _id, _name, path = *row

        max_number_of_blocks_per_facility_group.times.map {
          attrs = {
            id: nil,
            name: block_names[block_counter],
            parent_path: path,
            region_type: "block"
          }

          block_counter += 1
          FactoryBot.build(:region, attrs)
        }
      }
      Region.import(block_regions, returning: [:id, :name, :path])
    end

    def create_facilities(facility_group_results)
      facility_attrs = []
      facility_group_results.results.each do |row|
        facility_group_id, facility_group_name = *row
        facility_group_region = Region.find_by!(source_id: facility_group_id)
        number_facilities = number_of_facilities_per_facility_group
        state = facility_group_region.state_region
        blocks = facility_group_region.block_regions.pluck(:name)
        number_facilities.times {
          size = weighted_facility_size_sample
          type = SIZES_TO_TYPE.fetch(size).sample
          created_at = Faker::Time.between(from: 3.years.ago, to: 1.day.ago)
          attrs = {
            created_at: created_at,
            district: facility_group_name,
            facility_group_id: facility_group_id,
            facility_size: size,
            facility_type: type,
            state: state.name,
            updated_at: created_at,
            zone: blocks.sample
          }
          facility_attrs << FactoryBot.build(:facility, :seed, attrs)
        }
      end

      Facility.import(facility_attrs, returning: [:id, :name, :zone], on_duplicate_key_ignore: true)
    end

    def create_facility_regions(facility_results)
      facility_regions = facility_results.results.map { |row|
        id, name, block_name = *row
        block = Region.find_by!(name: block_name)
        attrs = {
          id: nil,
          name: name,
          parent_path: block&.path,
          region_type: "facility",
          source_id: id,
          source_type: "Facility"
        }
        FactoryBot.build(:region, attrs)
      }
      Region.import(facility_regions, on_duplicate_key_ignore: true)
    end
  end
end
