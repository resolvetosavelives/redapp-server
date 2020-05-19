require 'roo'

class Facility < ApplicationRecord
  include Mergeable
  include QuarterHelper
  extend FriendlyId

  before_save :clear_isd_code, unless: -> { teleconsultation_phone_number.present? }

  attribute :import, :boolean, default: false
  attribute :organization_name, :string
  attribute :facility_group_name, :string

  belongs_to :facility_group, optional: true

  has_many :phone_number_authentications, foreign_key: 'registration_facility_id'
  has_many :users, through: :phone_number_authentications

  has_many :encounters
  has_many :blood_pressures, through: :encounters, source: :blood_pressures
  has_many :blood_sugars, through: :encounters, source: :blood_sugars
  has_many :patients, -> { distinct }, through: :encounters
  has_many :prescription_drugs
  has_many :appointments

  has_many :registered_patients,
           class_name: "Patient",
           foreign_key: "registration_facility_id"
  has_many :registered_diabetes_patients,
           -> { with_diabetes },
           class_name: "Patient",
           foreign_key: "registration_facility_id"
  has_many :registered_hypertension_patients,
           -> { with_hypertension },
           class_name: "Patient",
           foreign_key: "registration_facility_id"

  enum facility_size: {
    community: "community",
    small: "small",
    medium: "medium",
    large: "large"
  }

  with_options if: :import do |facility|
    facility.validates :organization_name, presence: true
    facility.validates :facility_group_name, presence: true
    facility.validate :facility_name_presence
    facility.validate :organization_exists
    facility.validate :facility_group_exists
    facility.validate :facility_is_unique
  end

  with_options unless: :import do |facility|
    facility.validates :name, presence: true
  end

  validates :district, presence: true
  validates :state, presence: true
  validates :country, presence: true
  validates :pin, numericality: true, allow_blank: true
  validates :teleconsultation_isd_code, presence: true, if: :teleconsultation_enabled?
  validates :teleconsultation_phone_number, presence: true, if: :teleconsultation_enabled?
  validates :enable_teleconsultation, inclusion: { in: [true, false] }

  delegate :protocol, to: :facility_group, allow_nil: true
  delegate :organization, to: :facility_group, allow_nil: true
  delegate :follow_ups_by_period, to: :patients, prefix: :patient
  delegate :diabetes_follow_ups_by_period, to: :patients
  delegate :hypertension_follow_ups_by_period, to: :patients

  friendly_id :name, use: :slugged

  def cohort_analytics(period, prev_periods)
    query = CohortAnalyticsQuery.new(self.registered_hypertension_patients)
    query.patient_counts_by_period(period, prev_periods)
  end

  def dashboard_analytics(period: :month, prev_periods: 3, include_current_period: false)
    query = FacilityAnalyticsQuery.new(self,
                                       period,
                                       prev_periods,
                                       include_current_period: include_current_period)

    results = [
      query.registered_patients_by_period,
      query.total_registered_patients,
      query.follow_up_patients_by_period,
      query.total_calls_made_by_period
    ].compact

    return {} if results.blank?
    results.inject(&:deep_merge)
  end

  def self.parse_facilities(file_contents)
    facilities = []
    CSV.parse(file_contents, headers: true, converters: :strip_whitespace) do |row|
      facility = { organization_name: row['organization'],
                   facility_group_name: row['facility_group'],
                   name: row['facility_name'],
                   facility_type: row['facility_type'],
                   street_address: row['street_address (optional)'],
                   village_or_colony: row['village_or_colony (optional)'],
                   zone: row['zone_or_block (optional)'],
                   district: row['district'],
                   state: row['state'],
                   country: row['country'],
                   pin: row['pin (optional)'],
                   latitude: row['latitude (optional)'],
                   longitude: row['longitude (optional)'],
                   facility_size: row['size (optional)'],
                   enable_teleconsultation: row['enable_teleconsultation (true/false)'],
                   teleconsultation_phone_number: row['teleconsultation_phone_number'],
                   teleconsultation_isd_code: row['teleconsultation_isd_code'],
                   import: true }
      next if facility.except(:import).values.all?(&:blank?)

      facilities << facility
    end
    facilities
  end

  def organization_exists
    organization = Organization.find_by(name: organization_name)
    errors.add(:organization, "doesn't exist") if organization_name.present? && organization.blank?
  end

  def facility_group_exists
    organization = Organization.find_by(name: organization_name)
    facility_group = FacilityGroup.find_by(name: facility_group_name,
                                           organization_id: organization.id) if organization.present?
    if organization.present? && facility_group_name.present? && facility_group.blank?
      errors.add(:facility_group, "doesn't exist for the organization")
    end
  end

  def facility_is_unique
    organization = Organization.find_by(name: organization_name)
    facility_group = FacilityGroup.find_by(name: facility_group_name,
                                           organization_id: organization.id) if organization.present?
    facility = Facility.find_by(name: name, facility_group: facility_group.id) if facility_group.present?
    errors.add(:facility, 'already exists') if organization.present? && facility_group.present? && facility.present?

  end

  def facility_name_presence
    if name.blank?
      errors.add(:facility_name, "can't be blank")
    end
  end

  def diabetes_enabled?
    enable_diabetes_management.present?
  end

  def teleconsultation_enabled?
    enable_teleconsultation.present?
  end

  def teleconsultation_phone_number_with_isd
    return if teleconsultation_isd_code.blank? || teleconsultation_phone_number.blank?

    Phonelib.parse(teleconsultation_isd_code + teleconsultation_phone_number).full_e164
  end

  CSV::Converters[:strip_whitespace] = ->(value) { value.strip rescue value }

  private

  def clear_isd_code
    self.teleconsultation_isd_code = ""
  end
end
