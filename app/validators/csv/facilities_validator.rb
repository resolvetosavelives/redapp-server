class CSV::FacilitiesValidator
  STARTING_ROW = 2
  include Memery

  def self.validate(facilities)
    new(facilities).validate
  end

  def initialize(facilities)
    @facilities = facilities
  end

  def validate
    at_least_one_facility
    duplicate_rows
    facilities
  end

  private

  attr_reader :organization_name, :facility_group_name

  def at_least_one_facility
    errors << "Uploaded file doesn't contain any valid facilities" if facilities.blank?
  end

  def duplicate_rows
    fields = facilities.map { |facility| facility.slice(:organization_name, :facility_group_name, :name) }
    errors << "Uploaded file has duplicate facilities" if fields.count != fields.uniq.count
  end

  def facilities
    row_errors = []

    facilities.each.with_index(STARTING_ROW) do |import_facility, row_num|
      next if import_facility.valid?
      row_errors << [row_num, import_facility.errors.full_messages.to_sentence]
    end

    group_row_errors(row_errors).each { |error| errors << error } if row_errors.present?
  end

  def group_row_errors(row_errors)
    unique_errors = row_errors.map { |_row, message| message }.uniq
    unique_errors.map do |error|
      rows = row_errors.select { |row, message| row if error == message }.map { |row, _message| row }
      "Row(s) #{rows.join(", ")}: #{error}"
    end
  end

  class FacilityValidator
    include ActiveModel::Model

    def initialize(attributes = {})
      @attributes = attributes.to_hash.with_indifferent_access
      super(attributes)
    end

    validates :name, presence: true
    validates :organization_name, presence: true
    validates :facility_group_name, presence: true
    validate :facility_is_unique
    validate :organization_exists
    validate :facility_group_exists

    private

    def organization_exists
      if organization_name.present? && organization.blank?
        errors.add(:organization, "doesn't exist")
      end
    end

    def facility_group_exists
      if organization.present? && facility_group_name.present? && facility_group.blank?
        errors.add(:facility_group, "doesn't exist for the organization")
      end
    end

    def facility_is_unique
      if organization.present? && facility_group.present? && facility.present?
        errors.add(:facility, "already exists")
      end
    end

    memoize def organization
      Organization.find_by(name: organization_name)
    end

    memoize def facility_group
      FacilityGroup.find_by(name: facility_group_name, organization: organization)
    end

    memoize def facility
      Facility.find_by(name: name, facility_group: facility_group) if facility_group.present?
    end
  end
end
