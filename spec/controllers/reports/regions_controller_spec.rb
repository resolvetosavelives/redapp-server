require "rails_helper"

RSpec.describe Reports::RegionsController, type: :controller do
  let(:dec_2019_period) { Period.month(Date.parse("December 2019")) }
  let(:organization) { FactoryBot.create(:organization) }
  let(:cvho) do
    create(:admin, :supervisor, organization: organization).tap do |user|
      user.user_permissions << build(:user_permission, permission_slug: :view_cohort_reports, resource: organization)
    end
  end

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatientPerQuarter.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  context "index" do
    it "loads available districts" do
      sign_in(cvho.email_authentication)
      get :index
      expect(response).to be_successful
    end
  end

  context "details" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "is successful" do
      jan_2020 = Time.parse("January 1 2020")
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :details, params: {id: @facility.facility_group.slug, report_scope: "district"}
      end
      expect(response).to be_successful
    end
  end

  context "cohort" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "retrieves monthly cohort data by default" do
      jan_2020 = Time.parse("January 1 2020")
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :cohort, params: {id: @facility.facility_group.slug, report_scope: "district"}
      end
      expect(response).to be_successful
      data = assigns(:cohort_data)
      pending "need to change data output format"
      expect(data[:controlled_patients][Period.month("June 1 2020")]).to eq(1)
    end

    it "can retrieve quarterly cohort data" do
      jan_2020 = Time.parse("January 1 2020")
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -2))
      create(:blood_pressure, :under_control, recorded_at: jan_2020, patient: patient, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :cohort, params: {id: @facility.facility_group.slug, report_scope: "district", period: {type: "quarter", value: "Q2-2020"}}
        expect(response).to be_successful
        data = assigns(:cohort_data)
        expect(data.size).to eq(6)
        q2_data = data[1]
        expect(q2_data["results_in"]).to eq("Q1-2020")
        expect(q2_data["registered"]).to eq(1)
        expect(q2_data["controlled"]).to eq(1)
      end
    end
  end

  context "show" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "raises error if matching region slug found" do
      expect {
        sign_in(cvho.email_authentication)
        get :show, params: {id: "String-unknown", report_scope: "bad-report_scope"}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "retrieves district data" do
      jan_2020 = Time.parse("January 1 2020")
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -4))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.facility_group.slug, report_scope: "district"}
      end
      expect(response).to be_successful
      data = assigns(:data)
      expect(data[:controlled_patients].size).to eq(24) # sanity check
      expect(data[:controlled_patients][dec_2019_period]).to eq(1)
    end

    it "retrieves facility data" do
      jan_2020 = Time.parse("January 1 2020")
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -4))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.slug, report_scope: "facility"}
      end
      expect(response).to be_successful
      data = assigns(:data)
      expect(data[:controlled_patients].size).to eq(24) # sanity check
      expect(data[:controlled_patients][Date.parse("Dec 2019").to_period]).to eq(1)
    end
  end

  context "download" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "retrieves monthly cohort data by default" do
      jan_2020 = Time.parse("January 1 2020")
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :download, params: {id: @facility.facility_group.slug, report_scope: "district", period: "quarter", format: "csv"}
      end
      expect(response).to be_successful
    end
  end
end
