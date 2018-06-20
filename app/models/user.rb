class User < ApplicationRecord
  include Mergeable

  has_secure_password

  belongs_to :facility
  has_many :blood_pressures
  has_many :patients, through: :blood_pressures

  before_create :set_otp
  before_create :set_access_token

  validates :full_name, presence: true
  validates :phone_number, presence: true
  validates :password, allow_blank: true, length: { is: 4 }, format: { with: /[0-9]/, message: 'only allows numbers' }
  validate :presence_of_password

  def presence_of_password
    unless password_digest.present? || password.present?
      errors.add(:age, 'Either password_digest or password should be present')
    end
  end

  def set_otp
    generated_otp        = self.class.generate_otp
    self.otp             = generated_otp[:otp]
    self.otp_valid_until = generated_otp[:otp_valid_until]
  end

  def set_access_token
    self.access_token = self.class.generate_access_token
    self.is_access_token_valid = true
  end

  def self.generate_otp
    digits = (0..9).to_a
    otp    = ''
    6.times do
      otp += digits.sample.to_s
    end
    otp_valid_until = Time.now + ENV['USER_OTP_VALID_UNTIL_DELTA_IN_MINUTES'].to_i.minutes

    { otp: otp, otp_valid_until: otp_valid_until }
  end

  def self.generate_access_token
    SecureRandom.hex(32)
  end

  def access_token_valid?
    is_access_token_valid
  end
end
