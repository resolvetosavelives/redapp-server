require 'rails_helper'

RSpec.describe Api::V2::Analytics::UserAnalyticsController, type: :controller do
  let!(:request_user) { create(:user) }
  let!(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }

  before :each do
    request.env['HTTP_X_USER_ID'] = request_user.id
    request.env['HTTP_X_FACILITY_ID'] = request_facility.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  describe '#show' do
    context 'json' do
      it 'renders statistics for the facility as json' do
        get :show, format: :json
        response_body = JSON.parse(response.body, symbolize_names: true)

        expect(response_body.keys.map(&:to_sym))
          .to include(:daily,
                      :monthly,
                      :all_time,
                      :trophies,
                      :metadata)
      end
    end

    context 'html' do
      render_views

      describe 'facility has data' do
        it 'gets html when requested' do
          get :show, format: :html

          expect(response.status).to eq(200)
          expect(response.content_type).to eq('text/html')
        end

        it 'has the sync nudge card' do
          get :show, format: :html

          expect(response.body).to match(/Tap "Sync" on the home screen for new data/)
        end


        it 'has the registrations card' do
          get :show, format: :html

          expect(response.body).to match(/Registered/)
        end

        it 'has the follow-ups card' do
          get :show, format: :html

          expect(response.body).to match(/Follow-up hypertension patients/)
        end

        it 'has the hypertension control card' do
          get :show, format: :html

          expect(response.body).to match(/Hypertension control/)
        end

        context 'achievements' do
          it 'has the section visible' do
            Timecop.freeze("10:00 AM UTC") do
              #
              # create BPs (follow-ups)
              #
              patients = create_list(:patient, 3, registration_facility: request_facility)
              patients.each do |patient|
                [patient.recorded_at + 1.month,
                patient.recorded_at + 2.months,
                patient.recorded_at + 3.months,
                patient.recorded_at + 4.months].each do |date|
                  travel_to(date) do
                    create(:encounter,
                          :with_observables,
                          observable: create(:blood_pressure,
                                              patient: patient,
                                              facility: request_facility,
                                              user: request_user))
                  end
                end
              end

              get :show, format: :html
              expect(response.body).to match(/Achievements/)
            end
          end

          it 'is not visible if there are insufficient follow_ups' do
            get :show, format: :html
            expect(response.body).to_not match(/Achievements/)
          end
        end

        it 'has the footer' do
          get :show, format: :html

          expect(response.body).to match(/Notes/)
        end
      end
    end
  end
end
