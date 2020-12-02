require "rails_helper"

RSpec.describe ImportFacilitiesJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform_later" do
    let(:organization) { create(:organization, name: "OrgOne") }
    let!(:facility_group_2) { create(:facility_group, name: "FGTwo", organization_id: organization.id) }
    let(:facilities) do
      [
        attributes_for(:facility, organization_name: "OrgOne", facility_group_name: "FGTwo").except(:id),
        attributes_for(:facility, organization_name: "OrgOne", facility_group_name: "FGTwo").except(:id)
      ]
    end
    let(:job) { ImportFacilitiesJob.perform_later(facilities) }

    it "queues the job" do
      assert_enqueued_jobs 1 do
        job
      end
    end

    it "queues the job on the default queue" do
      expect(job.queue_name).to eq("default")
    end

    it "imports the specified facilities" do
      expect {
        perform_enqueued_jobs { job }
      }.to change(Facility, :count).by(2)
    end
  end
end
