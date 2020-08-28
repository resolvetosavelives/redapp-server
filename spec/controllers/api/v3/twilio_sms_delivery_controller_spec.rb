require "rails_helper"
require "./spec/support/twilio_sms_delivery_helper"

RSpec.configure do |c|
  c.include TwilioSMSDeliveryHelper
end

RSpec.describe Api::V3::TwilioSmsDeliveryController, type: :controller do
  describe "#create" do
    let!(:callback_url) { api_v3_twilio_sms_delivery_url(host: request.host) }

    let(:base_session_id) { SecureRandom.uuid }
    let!(:base_callback_params) do
      {"SmsSid" => base_session_id,
       "SmsStatus" => "delivered",
       "MessageSid" => base_session_id,
       "MessageStatus" => "delivered",
       "To" => Faker::PhoneNumber.phone_number,
       "AccountSid" => SecureRandom.uuid,
       "From" => "+15005550006",
       "ApiVersion" => "2010-04-01"}
    end

    context ":ok" do
      it "returns success when twilio signature is valid" do
        session_id = SecureRandom.uuid
        create(:twilio_sms_delivery_detail,
          session_id: session_id,
          result: "queued")
        params = base_callback_params.merge("MessageSid" => session_id)
        set_twilio_signature_header(callback_url, params)
        post :create, params: params

        expect(response).to have_http_status(200)
      end

      context "TwilioSmsDeliveryDetail" do
        it "updates the result for SmsSid and SmsStatus" do
          session_id = SecureRandom.uuid
          create(:twilio_sms_delivery_detail,
            session_id: session_id,
            result: "queued")
          params = base_callback_params.except("MessageSid", "MessageStatus")
            .merge("SmsSid" => session_id, "SmsStatus" => "sent")

          set_twilio_signature_header(callback_url, params)
          post :create, params: params

          twilio_sms_delivery_detail = TwilioSmsDeliveryDetail.find_by_session_id(session_id)
          expect(twilio_sms_delivery_detail.result).to eq("sent")
        end

        it "updates the result for MessageSid and MessageStatus" do
          session_id = SecureRandom.uuid
          create(:twilio_sms_delivery_detail,
            session_id: session_id,
            result: "queued")
          params = base_callback_params.merge("MessageSid" => session_id,
                                              "MessageStatus" => "sent")

          set_twilio_signature_header(callback_url, params)
          post :create, params: params

          twilio_sms_delivery_detail = TwilioSmsDeliveryDetail.find_by_session_id(session_id)
          expect(twilio_sms_delivery_detail.result).to eq("sent")
        end

        it "updates the result and delivered_on" do
          session_id = SecureRandom.uuid
          create(:twilio_sms_delivery_detail,
            session_id: session_id,
            result: "sent")
          params = base_callback_params.merge("MessageSid" => session_id,
                                              "MessageStatus" => "delivered")

          set_twilio_signature_header(callback_url, params)
          post :create, params: params

          twilio_sms_delivery_detail = TwilioSmsDeliveryDetail.find_by_session_id(session_id)
          expect(twilio_sms_delivery_detail.result).to eq("delivered")
          expect(twilio_sms_delivery_detail.delivered_on).to_not be_nil
        end

        it "does not update delivered_on if status is not delivered" do
          session_id = SecureRandom.uuid
          create(:twilio_sms_delivery_detail, session_id: session_id, result: "queued")

          params = base_callback_params.merge(
            "MessageSid" => session_id,
            "MessageStatus" => "sent"
          )

          set_twilio_signature_header(callback_url, params)
          post :create, params: params

          twilio_sms_delivery_detail = TwilioSmsDeliveryDetail.find_by_session_id(session_id)
          expect(twilio_sms_delivery_detail.delivered_on).to be_nil
        end

        it "schedules a fallback SMS if a whatsapp message failed" do
          session_id = SecureRandom.uuid
          fallback_time = 5.minutes.from_now
          communication = create(:communication, :missed_visit_whatsapp_reminder)
          create(:twilio_sms_delivery_detail, session_id: session_id, result: "queued", communication: communication)

          allow(Communication).to receive(:next_messaging_time).and_return(fallback_time)

          params = base_callback_params.merge(
            "MessageSid" => session_id,
            "MessageStatus" => "failed"
          )

          expect(AppointmentNotification::Worker).to receive(:perform_at).with(
            fallback_time,
            communication.appointment_id,
            "missed_visit_sms_reminder"
          )

          set_twilio_signature_header(callback_url, params)
          post :create, params: params
        end

        it "does not schedule a fallback SMS if an SMS failed" do
          session_id = SecureRandom.uuid
          fallback_time = 5.minutes.from_now
          communication = create(:communication, :missed_visit_sms_reminder)
          create(:twilio_sms_delivery_detail, session_id: session_id, result: "queued", communication: communication)

          allow(Communication).to receive(:next_messaging_time).and_return(fallback_time)

          params = base_callback_params.merge(
            "MessageSid" => session_id,
            "MessageStatus" => "failed"
          )

          expect(AppointmentNotification::Worker).not_to receive(:perform_at)

          set_twilio_signature_header(callback_url, params)
          post :create, params: params
        end
      end
    end

    context ":forbidden" do
      it "returns 403 when the twilio signature is invalid" do
        sig_with_invalid_params = {}
        set_twilio_signature_header(callback_url, sig_with_invalid_params)
        post :create, params: base_callback_params

        expect(response).to have_http_status(403)
        expect(TwilioSmsDeliveryDetail.count).to be(0)
      end
    end
  end
end
