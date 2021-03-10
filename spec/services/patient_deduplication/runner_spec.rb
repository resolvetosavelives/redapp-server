require "rails_helper"

RSpec.describe PatientDeduplication::Runner do
  describe "#perform" do
    it "catches any exceptions and reports them" do
      patient_1 = create(:patient, full_name: "Patient")
      passport_id = patient_1.business_identifiers.first.identifier

      patient_2 = create(:patient, full_name: "Patient")
      patient_2.business_identifiers.first.update(identifier: passport_id)

      allow(PatientDeduplication::Deduplicator).to receive(:new).and_raise("an exception")

      instance = described_class.new(PatientDeduplication::Strategies.identifier_and_full_name_match)
      expect(instance).to receive(:handle_error)

      instance.perform
    end

    it "reports success and failures" do
      patient_1 = create(:patient, full_name: "Patient")
      passport_id = patient_1.business_identifiers.first.identifier

      patient_2 = create(:patient, full_name: "Patient")
      patient_2.business_identifiers.first.update(identifier: passport_id)

      instance = described_class.new(PatientDeduplication::Strategies.identifier_and_full_name_match)
      instance.perform
      expect(instance.report_stats).to eq({processed: {total: 2,
                                                       distinct: 1},
                                           merged: {total: 2,
                                                    distinct: 1,
                                                    total_failures: 0,
                                                    distinct_failure: 0}})
    end
  end
end
