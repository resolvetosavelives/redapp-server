require "rails_helper"

RSpec.describe AppointmentNotification::Worker, type: :job do
  describe "#perform" do
    before do
      Flipper.enable(:notifications)
      allow(Statsd.instance).to receive(:increment).with(anything)
    end

    let(:notification) {
      create(:notification,
        subject: create(:appointment),
        status: "scheduled",
        message: "#{Notification::APPOINTMENT_REMINDER_MSG_PREFIX}.whatsapp")
    }

    def mock_successful_delivery
      response_double = double
      allow_any_instance_of(TwilioApiService).to receive(:response).and_return(response_double)
      allow(response_double).to receive(:status).and_return("sent")
      allow(response_double).to receive(:sid).and_return("12345")
      twilio_client = double
      allow_any_instance_of(TwilioApiService).to receive(:client).and_return(twilio_client)
      allow(twilio_client).to receive_message_chain("messages.create")
    end

    it "logs but creates nothing when notifications and experiment flags are disabled" do
      Flipper.disable(:notifications)
      Flipper.disable(:experiment)

      expect(Statsd.instance).to receive(:increment).with("appointment_notification.worker.skipped.feature_disabled")
      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.not_to change { Communication.count }
    end

    it "creates communications when notifications is enabled" do
      mock_successful_delivery

      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.to change { Communication.count }.by(1)
    end

    it "creates communications when experiment is enabled" do
      Flipper.disable(:notifications)
      Flipper.enable(:experiment)

      mock_successful_delivery

      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.to change { Communication.count }.by(1)
    end

    it "sends a whatsapp message when notification's next_communication_type is whatsapp" do
      mock_successful_delivery
      allow_any_instance_of(Notification).to receive(:next_communication_type).and_return("whatsapp")

      expect(Statsd.instance).to receive(:increment).with("appointment_notification.worker.sent.whatsapp")
      expect_any_instance_of(TwilioApiService).to receive(:send_whatsapp)
      described_class.perform_async(notification.id)
      described_class.drain
    end

    it "sends sms when notification's next_communication_type is sms" do
      mock_successful_delivery
      allow_any_instance_of(Notification).to receive(:next_communication_type).and_return("sms")

      expect(Statsd.instance).to receive(:increment).with("appointment_notification.worker.sent.sms")
      expect_any_instance_of(TwilioApiService).to receive(:send_sms)
      described_class.perform_async(notification.id)
      described_class.drain
    end

    it "does not send a communication when notification's next_communication_type is nil" do
      mock_successful_delivery
      allow_any_instance_of(Notification).to receive(:next_communication_type).and_return(nil)

      expect(Statsd.instance).to receive(:increment).with("appointment_notification.worker.skipped.no_next_communication_type")
      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.not_to change { Communication.count }
    end

    it "raises an error when next_communication_type is not supported" do
      allow_any_instance_of(Notification).to receive(:next_communication_type).and_return("aol_instant_messenger")

      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.to raise_error(StandardError)
        .with_message("AppointmentNotification::Worker is not configured to handle communication type aol_instant_messenger")
    end

    it "creates a Communication with twilio response status and sid" do
      mock_successful_delivery

      expect(Communication).to receive(:create_with_twilio_details!).with(
        appointment: notification.subject,
        notification: notification,
        twilio_sid: "12345",
        twilio_msg_status: "sent",
        communication_type: "sms"
      ).and_call_original
      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.to change { Communication.count }.by(1)
    end

    it "does not create a TwilioApiService or Communication if notification has been previously attempted by all available methods" do
      create(:communication, :whatsapp, notification: notification)
      create(:communication, :sms, notification: notification)

      expect(Statsd.instance).to receive(:increment).with("appointment_notification.worker.skipped.no_next_communication_type")
      expect_any_instance_of(TwilioApiService).not_to receive(:send_whatsapp)
      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.not_to change { Communication.count }
    end

    it "does not attempt to resend the same communication type even if previous attempt failed" do
      mock_successful_delivery

      previous_whatsapp = create(:communication, :whatsapp, notification: notification)
      create(:twilio_sms_delivery_detail, :failed, communication: previous_whatsapp)

      expect_any_instance_of(TwilioApiService).to receive(:send_sms)
      described_class.perform_async(notification.id)
      described_class.drain
    end

    it "updates the appointment notification status to 'sent'" do
      mock_successful_delivery

      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.to change { notification.reload.status }.from("scheduled").to("sent")
    end

    it "localizes the message based on facility state, not patient address" do
      mock_successful_delivery
      notification.patient.address.update!(state: "maharashtra")
      notification.subject.facility.update!(state: "punjab")
      localized_message = I18n.t(
        notification.message,
        {
          facility_name: notification.subject.facility.name,
          locale: "pa-Guru-IN"
        }
      )

      expect_any_instance_of(TwilioApiService).to receive(:send_sms).with(
        notification.patient.latest_mobile_number,
        localized_message,
        "https://localhost/api/v3/twilio_sms_delivery"
      )
      described_class.perform_async(notification.id)
      described_class.drain
    end

    it "does not create a communication or update notification status if the notification status is not 'scheduled'" do
      notification = create(:notification, status: "pending")

      expect(Statsd.instance).to receive(:increment).with("appointment_notification.worker.skipped.not_scheduled")
      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.not_to change { Communication.count }
      expect(notification.reload.status).to eq("pending")
    end

    it "does not create a communication or update notification status if an error is received from twilio" do
      expect {
        described_class.perform_async(notification.id)
        begin
          described_class.drain
        rescue TwilioApiService::Error
        end
      }.not_to change { Communication.count }
      expect(notification.reload.status).to eq("scheduled")
    end

    it "raises an error if appointment notification is not found" do
      expect {
        described_class.perform_async("does-not-exist")
        described_class.drain
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not send if the notification is cancelled" do
      mock_successful_delivery
      notification.update!(status: "cancelled")
      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.not_to change { Communication.count }
    end

    it "does not send if the notification belongs to a cancelled experiment" do
      mock_successful_delivery
      experiment = create(:experiment, state: "cancelled")
      notification.update!(experiment_id: experiment.id)
      expect {
        described_class.perform_async(notification.id)
        described_class.drain
      }.not_to change { Communication.count }
      expect(notification.reload.status).to eq("scheduled")
    end

    describe "medication reminder experiment" do
      it "provides a sender if available" do
        mock_successful_delivery
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with("TWILIO_COVID_REMINDER_NUMBERS", "").and_return("+testnumber111,+testnumber222,+testnumber333")
        experiment = create(:experiment, experiment_type: "medication_reminder")
        allow_any_instance_of(Notification).to receive(:next_communication_type).and_return("sms")
        allow_any_instance_of(Notification).to receive(:experiment).and_return(experiment)

        expect(TwilioApiService).to receive(:new).with(sms_sender: /testnumber/).and_call_original
        expect_any_instance_of(TwilioApiService).to receive(:send_sms)
        described_class.perform_async(notification.id)
        described_class.drain
      end

      it "does not provide a sender if unavailable" do
        mock_successful_delivery
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with("TWILIO_COVID_REMINDER_NUMBERS", "").and_return("")
        experiment = create(:experiment, experiment_type: "medication_reminder")
        allow_any_instance_of(Notification).to receive(:next_communication_type).and_return("sms")
        allow_any_instance_of(Notification).to receive(:experiment).and_return(experiment)

        expect(TwilioApiService).to receive(:new).with(no_args).and_call_original
        expect_any_instance_of(TwilioApiService).to receive(:send_sms)
        described_class.perform_async(notification.id)
        described_class.drain
      end

      it "does not provide a sender if the notification is not part of a medication reminder experiment" do
        mock_successful_delivery
        experiment = create(:experiment, experiment_type: "current_patients")
        allow_any_instance_of(Notification).to receive(:next_communication_type).and_return("sms")
        allow_any_instance_of(Notification).to receive(:experiment).and_return(experiment)

        expect(TwilioApiService).to receive(:new).with(no_args).and_call_original
        expect_any_instance_of(TwilioApiService).to receive(:send_sms)
        described_class.perform_async(notification.id)
        described_class.drain
      end

      it "does not provide a sender if the notification does not have an experiment" do
        mock_successful_delivery
        allow_any_instance_of(Notification).to receive(:next_communication_type).and_return("sms")
        allow_any_instance_of(Notification).to receive(:experiment).and_return(nil)

        expect(TwilioApiService).to receive(:new).with(no_args).and_call_original
        expect_any_instance_of(TwilioApiService).to receive(:send_sms)
        described_class.perform_async(notification.id)
        described_class.drain
      end
    end
  end
end
