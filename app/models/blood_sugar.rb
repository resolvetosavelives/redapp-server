class BloodSugar < ApplicationRecord
  include Mergeable
  include Observeable

  belongs_to :patient, optional: true
  belongs_to :user, optional: true
  belongs_to :facility, optional: true

  has_one :observation, as: :observable
  has_one :encounter, through: :observation

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  enum blood_sugar_type: {
    random: 'random',
    post_prandial: 'post_prandial',
    fasting: 'fasting',
    hba1c: 'hba1c'
  }, _prefix: true

  scope :without_hba1c, -> { where.not(blood_sugar_type: :hba1c) }

  THRESHOLDS = {
    high: { random: 300,
            post_prandial: 300,
            fasting: 200,
            hba1c: 9.0 }
   }.with_indifferent_access.freeze

  def diabetic?
    blood_sugar_value >= THRESHOLDS[:high][blood_sugar_type]
  end
end
