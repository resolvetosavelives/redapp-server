require 'rails_helper'

describe Patient, type: :model do
  describe 'Associations' do
    it { should belong_to(:address) }
    it { should have_many(:phone_numbers) }
    it { should have_many(:blood_pressures) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:device_created_at)}
    it { should validate_presence_of(:device_updated_at)}
  end

  describe 'Validations' do
    it { should validate_presence_of(:device_created_at)}
    it { should validate_presence_of(:device_updated_at)}
  end
end