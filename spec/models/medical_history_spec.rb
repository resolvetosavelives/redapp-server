require 'rails_helper'

describe MedicalHistory, type: :model do
  describe 'Associations' do
    it { should belong_to(:patient) }
  end

  describe 'Validations' do
    it_behaves_like 'a record that validates device timestamps'
    it { should validate_presence_of(:device_updated_at) }
  end

  describe 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end

  describe 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end

  describe '#risk_history?' do
    it 'returns true if there was a prior heart attack' do
      patient = create(:patient)
      create(:medical_history, prior_heart_attack_boolean: true, patient: patient)

      expect(patient.medical_history.indicates_risk?).to eq(true)
    end

    it 'returns true if there was a prior stroke' do
      patient = create(:patient)
      create(:medical_history, prior_stroke_boolean: true, patient: patient)

      expect(patient.medical_history.indicates_risk?).to eq(true)
    end

    it 'returns true if there is diabetes history' do
      patient = create(:patient)
      create(:medical_history, diabetes_boolean: true, patient: patient)

      expect(patient.medical_history.indicates_risk?).to eq(true)
    end

    it 'returns true if there was chronic kidney disease' do
      patient = create(:patient)
      create(:medical_history, chronic_kidney_disease_boolean: true, patient: patient)

      expect(patient.medical_history.indicates_risk?).to eq(true)
    end
  end
end
