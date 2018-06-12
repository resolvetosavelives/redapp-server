require 'rails_helper'

RSpec.describe PrescriptionDrug, type: :model do
  describe 'Validations' do
    it_behaves_like 'a record that can be synced remotely'
  end

  describe 'Associations' do
    it { should belong_to(:facility)}
    it { should belong_to(:patient)}
  end
end
