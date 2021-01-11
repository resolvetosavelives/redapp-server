class ProtocolDrug < ApplicationRecord
  belongs_to :protocol
  has_many :drug_stocks

  before_create :assign_id

  validates :name, presence: true
  validates :dosage, presence: true

  def assign_id
    self.id = SecureRandom.uuid
  end
end
