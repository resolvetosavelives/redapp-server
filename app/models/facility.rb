require "roo"

class Facility < ApplicationRecord
  include Mergeable
  include QuarterHelper
  include PgSearch::Model
  include LiberalEnum

  extend FriendlyId
  extend RegionSource

  friendly_id :name, use: :slugged

  belongs_to :facility_group, optional: true

  has_many :business_identifiers, class_name: "FacilityBusinessIdentifier"
  has_many :phone_number_authentications, foreign_key: "registration_facility_id"
  has_many :users, through: :phone_number_authentications
  has_and_belongs_to_many :teleconsultation_medical_officers,
    -> { distinct },
    class_name: "User",
    association_foreign_key: :user_id,
    join_table: "facilities_teleconsultation_medical_officers"

  has_many :encounters
  has_many :blood_pressures, through: :encounters, source: :blood_pressures
  has_many :blood_sugars, through: :encounters, source: :blood_sugars
  has_many :patients, -> { distinct }, through: :encounters
  has_many :prescription_drugs
  has_many :appointments
  has_many :teleconsultations
  has_many :drug_stocks

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
  has_many :assigned_patients,
    class_name: "Patient",
    foreign_key: "assigned_facility_id"
  has_many :assigned_hypertension_patients,
    -> { with_hypertension },
    class_name: "Patient",
    foreign_key: "assigned_facility_id"

  pg_search_scope :search_by_name, against: {name: "A", slug: "B"}, using: {tsearch: {prefix: true}}
  scope :with_block_region_id, -> {
    joins("INNER JOIN regions facility_regions ON facility_regions.source_id = facilities.id")
      .joins("INNER JOIN regions block_region ON block_region.path @> facility_regions.path AND block_region.region_type = 'block'")
      .select("block_region.id AS block_region_id, facilities.*")
  }

  scope :with_region_information, -> {
    joins("INNER JOIN reporting_facilities on reporting_facilities.facility_id = facilities.id")
      .select("facilities.*, reporting_facilities.*")
  }

  enum facility_size: {
    community: "community",
    small: "small",
    medium: "medium",
    large: "large"
  }

  liberal_enum :facility_size

  auto_strip_attributes :name, squish: true, upcase_first: true
  auto_strip_attributes :district, squish: true, upcase_first: true
  auto_strip_attributes :zone, squish: true, upcase_first: true

  attribute :organization_name, :string
  attribute :facility_group_name, :string

  alias_attribute :block, :zone

  validates :name, presence: true
  validates :district, presence: true
  validates :slug, presence: true
  # this validation (and the field) should go away from facility after regions become first-class
  validates :state, presence: true, if: -> { facility_group.present? }
  validates :country, presence: true
  validates :zone, presence: true, on: :create
  validates :pin, numericality: true, allow_blank: true
  validates :facility_size,
    inclusion: {
      in: facility_sizes.values,
      message: "not in #{facility_sizes.values.join(", ")}",
      allow_blank: true
    }
  validates :enable_teleconsultation, inclusion: {in: [true, false]}
  validates :teleconsultation_medical_officers,
    presence: {
      if: :enable_teleconsultation,
      message: "must be added to enable teleconsultation"
    }
  validates :enable_diabetes_management, inclusion: {in: [true, false]}
  validate :valid_block, if: -> { facility_group.present? }

  delegate :protocol, to: :facility_group, allow_nil: true
  delegate :organization, :organization_id, to: :facility_group, allow_nil: true
  delegate :follow_ups_by_period, to: :patients, prefix: :patient
  delegate :district_region?, :block_region?, :facility_region?, :region_type, to: :region
  delegate :cache_key, :cache_version, to: :region

  def self.parse_facilities_from_file(file_contents)
    Csv::FacilitiesParser.parse(file_contents)
  end

  # ----------------
  # Region callbacks
  #
  # * These callbacks are medium-term temporary.
  # * This class and the Region callbacks should ideally be totally superseded by the Region class.
  # * Keep the callbacks simple (avoid branching and optimization), idempotent (if possible) and loud when things break.
  after_create :make_region
  after_update :update_region

  def make_region
    return if region&.persisted?

    create_region!(
      name: name,
      reparent_to: block_region,
      region_type: Region.region_types[:facility]
    )
  end

  private def update_region
    region.reparent_to = block_region
    region.name = name
    region.save!
  end

  def block_region
    facility_group.region.block_regions.find_by(name: block)
  end

  # Remove me after region_reports is mainline
  def source
    self
  end

  def hypertension_follow_ups_by_period(*args)
    patients.hypertension_follow_ups_by_period(*args).where(blood_pressures: {facility: self})
  end

  def diabetes_follow_ups_by_period(*args)
    patients.diabetes_follow_ups_by_period(*args).where(blood_sugars: {facility: self})
  end

  # For compatibility w/ parent FacilityGroups
  def facilities
    [self]
  end

  def facility_ids
    [id]
  end

  def child_region_type
    nil
  end

  def cohort_analytics(period:, prev_periods:)
    CohortAnalyticsQuery.new(self, period: period, prev_periods: prev_periods).call
  end

  def dashboard_analytics(period: :month, prev_periods: 3, include_current_period: false)
    FacilityAnalyticsQuery.new(self, period, prev_periods, include_current_period: include_current_period).call
  end

  def diabetes_enabled?
    enable_diabetes_management.present?
  end

  def opd_load_estimated?
    monthly_estimated_opd_load.present?
  end

  def opd_load
    monthly_estimated_opd_load || opd_load_for_facility_size
  end

  def opd_load_for_facility_size
    case facility_size
    when "community" then 450
    when "small" then 1800
    when "medium" then 3000
    when "large" then 7500
    else 450
    end
  end

  def teleconsultation_enabled?
    enable_teleconsultation.present?
  end

  def teleconsultation_phone_number_with_isd
    teleconsultation_phone_numbers_with_isd.first
  end

  def teleconsultation_phone_numbers_with_isd
    teleconsultation_medical_officers.map(&:full_teleconsultation_phone_number)
  end

  def discardable?
    registered_patients.none? && blood_pressures.none? && blood_sugars.none? && appointments.none?
  end

  def valid_block
    unless facility_group.region.block_regions.pluck(:name).include?(block)
      errors.add(:zone, "not present in the facility group")
    end
  end

  def prioritized_patients
    registered_patients.with_discarded
  end

  def self.localized_facility_size(facility_size)
    return unless facility_size
    I18n.t("activerecord.facility.facility_size.#{facility_size}", default: facility_size.capitalize)
  end

  def localized_facility_size
    return unless facility_size
    I18n.t("activerecord.facility.facility_size.#{facility_size}", default: facility_size.capitalize)
  end

  def locale
    LOCALE_MAP.dig(country.downcase, state.downcase) || LOCALE_MAP.dig(country.downcase, "default") || LOCALE_MAP["default"]
  end

  LOCALE_MAP = {
    "bangladesh" => {"default" => "bn-BD"},
    "default" => "en",
    "ethiopia" => {
      "addis ababa" => "am-ET",
      "amhara" => "am-ET",
      "default" => "am-ET",
      "dire dawa" => "am-ET",
      "oromia" => "om-ET",
      "sidama" => "sid-ET",
      "somali" => "so-ET",
      "tigray" => "ti-ET"
    },
    "india" => {
      "andhra pradesh" => "te-IN",
      "bihar" => "hi-IN",
      "default" => "hi-IN",
      "jharkhand" => "hi-IN",
      "karnataka" => "kn-IN",
      "maharashtra" => "mr-IN",
      "nagaland" => "en",
      "puducherry" => "ta-IN",
      "punjab" => "pa-Guru-IN",
      "rajasthan" => "hi-IN",
      "sikkim" => "hi-IN",
      "tamil nadu" => "ta-IN",
      "telangana" => "te-IN",
      "uttar pradesh" => "hi-IN",
      "west bengal" => "bn-IN"
    }
  }.freeze
end
