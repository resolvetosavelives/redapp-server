require "rails_helper"

RSpec.describe Reports::RegionsController, type: :controller do
  let(:jan_2020) { Time.parse("January 1 2020") }
  let(:dec_2019_period) { Period.month(Date.parse("December 2019")) }
  let(:organization) { FactoryBot.create(:organization) }
  let(:cvho) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatientPerQuarter.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  context "index" do
    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "loads available districts" do
      sign_in(cvho.email_authentication)
      get :index
      expect(response).to be_successful
    end
  end

  context "details" do
    render_views

    before do
      enable_flag(:regions_prep)
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end
    context "region_reports disabled" do
      before { Flipper.disable(:region_reports) }

      it "is successful for a facility group" do
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

    context "region_reports enabled" do
      before { Flipper.enable(:region_reports, cvho) }

      it "is successful for a facility" do
        patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
        create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
        create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
        refresh_views

        Timecop.freeze("June 1 2020") do
          sign_in(cvho.email_authentication)
          get :details, params: {id: @facility.region.slug, report_scope: "facility"}
        end
        expect(response).to be_successful
      end

      it "is successful for a district" do
        patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
        create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
        create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
        refresh_views

        Timecop.freeze("June 1 2020") do
          sign_in(cvho.email_authentication)
          get :details, params: {id: @facility.facility_group.region.slug, report_scope: "district"}
        end
        expect(response).to be_successful
      end

      it "is successful for a block" do
        patient_2 = create(:patient, registration_facility: @facility, recorded_at: "June 01 2019 00:00:00 UTC", registration_user: cvho)
        create(:blood_pressure, :hypertensive, recorded_at: "Feb 2020", facility: @facility, patient: patient_2, user: cvho)

        patient_1 = create(:patient, registration_facility: @facility, recorded_at: "September 01 2019 00:00:00 UTC", registration_user: cvho)
        create(:blood_pressure, :under_control, recorded_at: "December 10th 2019", patient: patient_1, facility: @facility, user: cvho)
        create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility, user: cvho)

        refresh_views

        block = @facility.region.block_region

        Timecop.freeze("June 1 2020") do
          sign_in(cvho.email_authentication)
          get :details, params: {id: block.slug, report_scope: "block"}
        end
        expect(response).to be_successful
      end
    end
  end

  context "cohort" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "retrieves monthly cohort data by default" do
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

    it "returns period info for every month" do
      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.facility_group.slug, report_scope: "district"}
      end
      data = assigns(:data)
      period_hash = {
        "name" => "Dec-2019",
        "bp_control_start_date" => "1-Oct-2019",
        "bp_control_end_date" => "31-Dec-2019"
      }
      expect(data[:period_info][dec_2019_period]).to eq(period_hash)
    end

    it "retrieves district data" do
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
      expect(data[:controlled_patients].size).to eq(9) # sanity check
      expect(data[:controlled_patients][dec_2019_period]).to eq(1)
    end

    it "retrieves facility data" do
      Time.parse("January 1 2020")
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
      expect(data[:controlled_patients].size).to eq(9) # sanity check
      expect(data[:controlled_patients][Date.parse("Dec 2019").to_period]).to eq(1)
    end

    it "retrieves facility district data" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -4))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.district, report_scope: "facility_district"}
      end
      expect(response).to be_successful
      data = assigns(:data)
      expect(data[:controlled_patients].size).to eq(9) # sanity check
      expect(data[:controlled_patients][dec_2019_period]).to eq(1)
    end
  end

  context "show v2" do
    render_views_on_ci

    before do
      Flipper.enable(:regions_prep)
      Flipper.enable_actor(:region_reports, cvho)
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "raises error if matching region slug found" do
      expect {
        sign_in(cvho.email_authentication)
        get :show, params: {id: "String-unknown", report_scope: "bad-report_scope"}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns period info for every month" do
      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.facility_group.slug, report_scope: "district"}
      end
      data = assigns(:data)
      period_hash = {
        "name" => "Dec-2019",
        "bp_control_start_date" => "1-Oct-2019",
        "bp_control_end_date" => "31-Dec-2019"
      }
      expect(data[:period_info][dec_2019_period]).to eq(period_hash)
    end

    it "retrieves district data" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -4))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      fg = @facility.facility_group
      expect(fg.region).to_not be_nil
      expect(fg.slug).to eq(fg.region.slug)
      expect(fg.region.facilities).to contain_exactly(@facility)

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.facility_group.slug, report_scope: "district"}
      end
      expect(response).to be_successful
      data = assigns(:data)
      expect(data[:controlled_patients].size).to eq(9) # sanity check
      expect(data[:controlled_patients][dec_2019_period]).to eq(1)
    end

    it "retrieves facility data" do
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
      expect(data[:controlled_patients].size).to eq(9) # sanity check
      expect(data[:controlled_patients][Date.parse("Dec 2019").to_period]).to eq(1)
    end

    it "retrieves block data" do
      patient_2 = create(:patient, registration_facility: @facility, recorded_at: "June 01 2019 00:00:00 UTC", registration_user: cvho)
      create(:blood_pressure, :hypertensive, recorded_at: "Feb 2020", facility: @facility, patient: patient_2, user: cvho)

      patient_1 = create(:patient, registration_facility: @facility, recorded_at: "September 01 2019 00:00:00 UTC", registration_user: cvho)
      create(:blood_pressure, :under_control, recorded_at: "December 10th 2019", patient: patient_1, facility: @facility, user: cvho)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility, user: cvho)

      refresh_views

      block = @facility.region.block_region
      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: block.to_param, report_scope: "block"}
      end
      expect(response).to be_successful
      data = assigns(:data)

      expect(data[:registrations][Period.month("June 2019")]).to eq(1)
      expect(data[:registrations][Period.month("September 2019")]).to eq(1)
      expect(data[:controlled_patients][Period.month("Dec 2019")]).to eq(1)
      expect(data[:uncontrolled_patients][Period.month("Feb 2020")]).to eq(1)
      expect(data[:uncontrolled_patients_rate][Period.month("Feb 2020")]).to eq(50)
      expect(data[:missed_visits][Period.month("September 2019")]).to eq(1)
      expect(data[:missed_visits][Period.month("May 2020")]).to eq(2)
    end

    it "retrieves facility district data" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -4))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.district, report_scope: "facility_district"}
      end
      expect(response).to be_successful
      data = assigns(:data)
      expect(data[:controlled_patients].size).to eq(9) # sanity check
      expect(data[:controlled_patients][dec_2019_period]).to eq(1)
    end
  end

  context "download" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "retrieves cohort data for a facility" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :download, params: {id: @facility.slug, report_scope: "facility", period: "month", format: "csv"}
      end
      expect(response).to be_successful
      expect(response.body).to include("CHC Barnagar Monthly Cohort Report")
      expect(response.headers["Content-Disposition"]).to include('filename="facility-monthly-cohort-report_CHC-Barnagar')
    end

    it "retrieves cohort data for a facility group" do
      facility_group = @facility.facility_group
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :download, params: {id: facility_group.slug, report_scope: "district", period: "quarter", format: "csv"}
      end
      expect(response).to be_successful
      expect(response.body).to include("#{facility_group.name} Quarterly Cohort Report")
      expect(response.headers["Content-Disposition"]).to include('filename="facility_group-quarterly-cohort-report_')
    end

    it "retrieves cohort data for a facility district" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :download, params: {id: @facility.district, report_scope: "facility_district", period: "quarter", format: "csv"}
      end
      expect(response).to be_successful
      expect(response.body).to include("#{@facility.district} Quarterly Cohort Report")
      expect(response.headers["Content-Disposition"]).to include('filename="facility_district-quarterly-cohort-report_')
    end
  end

  describe "#whatsapp_graphics" do
    render_views
    before { Flipper.enable(:regions_prep) }

    context "region reports disabled" do
      before do
        Flipper.disable(:region_reports, cvho)
        @facility_group = create(:facility_group, organization: organization)
        @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
        sign_in(cvho.email_authentication)
      end

      context "html requested" do
        it "renders graphics_header partial" do
          get :whatsapp_graphics, format: :html, params: {id: @facility.slug, report_scope: "facility"}

          expect(response).to be_ok
          expect(response).to render_template("shared/graphics/_graphics_partial")
        end
      end

      context "png requested" do
        it "renders the image template for downloading" do
          get :whatsapp_graphics, format: :png, params: {id: @facility_group.slug, report_scope: "district"}

          expect(response).to be_ok
          expect(response).to render_template("shared/graphics/image_template")
        end
      end
    end

    context "region reports enabled" do
      before do
        Flipper.enable(:region_reports, cvho)
        @facility_group = create(:facility_group, organization: organization)
        @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
        sign_in(cvho.email_authentication)
      end

      context "html requested" do
        it "renders graphics_header partial" do
          get :whatsapp_graphics, format: :html, params: {id: @facility.region.slug, report_scope: "facility"}

          expect(response).to be_ok
          expect(response).to render_template("shared/graphics/_graphics_partial")
        end
      end

      context "png requested" do
        it "renders the image template for downloading" do
          get :whatsapp_graphics, format: :png, params: {id: @facility_group.region.slug, report_scope: "district"}

          expect(response).to be_ok
          expect(response).to render_template("shared/graphics/image_template")
        end
      end
    end
  end
end
