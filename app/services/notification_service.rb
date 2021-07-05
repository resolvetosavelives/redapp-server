class NotificationService
  DEFAULT_LOCALE = :en

  attr_reader :client
  attr_reader :error
  attr_reader :response
  attr_reader :twilio_sender_sms_number
  attr_reader :twilio_sender_whatsapp_number

  # See https://www.twilio.com/docs/iam/test-credentials#test-sms-messages-parameters-From
  # https://www.twilio.com/docs/whatsapp/sandbox#what-is-the-twilio-sandbox-for-whatsapp
  TWILIO_TEST_SMS_NUMBER = "+15005550006"
  TWILIO_TEST_WHATSAPP_NUMBER = "+14155238886"

  def initialize(sms_sender: nil)
    @test_mode = !SimpleServer.env.production? && ENV["HEROKU_APP_NAME"] != "simple-review-pr-2660"

    @twilio_account_sid = ENV.fetch("TWILIO_ACCOUNT_SID")
    @twilio_auth_token = ENV.fetch("TWILIO_AUTH_TOKEN")

    @twilio_test_account_sid = ENV.fetch("TWILIO_TEST_ACCOUNT_SID")
    @twilio_test_auth_token = ENV.fetch("TWILIO_TEST_AUTH_TOKEN")

    @twilio_sender_sms_number = if test_mode?
      TWILIO_TEST_SMS_NUMBER
    elsif sms_sender
      sms_sender
    else
      ENV.fetch("TWILIO_PHONE_NUMBER")
    end
    @twilio_sender_whatsapp_number = test_mode? ? TWILIO_TEST_WHATSAPP_NUMBER : ENV.fetch("TWILIO_PHONE_NUMBER")

    @client = if @test_mode
      test_client
    else
      prod_client
    end
  end

  def test_mode?
    @test_mode
  end

  def prod_client
    @prod_client ||= Twilio::REST::Client.new(@twilio_account_sid, @twilio_auth_token)
  end

  def test_client
    @test_client ||= Twilio::REST::Client.new(@twilio_test_account_sid, @twilio_test_auth_token)
  end

  def send_sms(recipient_number, message, callback_url = nil)
    sender_number = twilio_sender_sms_number
    recipient_number = parse_phone_number(recipient_number)

    send_twilio_message(sender_number, recipient_number, message, callback_url)
  end

  def send_whatsapp(recipient_number, message, callback_url = nil)
    sender_number = "whatsapp:" + twilio_sender_whatsapp_number
    recipient_number = "whatsapp:" + parse_phone_number(recipient_number)

    send_twilio_message(sender_number, recipient_number, message, callback_url)
  end

  def parse_phone_number(number)
    parsed_number = Phonelib.parse(number, Rails.application.config.country[:abbreviation]).raw_national
    default_country_code + parsed_number
  end

  def failed?
    error.present?
  end

  private

  def default_country_code
    Rails.application.config.country[:sms_country_code]
  end

  def send_twilio_message(sender_number, recipient_number, message, callback_url = nil)
    @response = client.messages.create(
      from: sender_number,
      to: recipient_number,
      status_callback: callback_url,
      body: message
    )
  rescue Twilio::REST::TwilioError => exception
    @error = exception
    report_error(exception)
  end

  def report_error(e)
    Sentry.capture_message(
      "Error while processing notification",
      extra: {
        exception: e.to_s
      },
      tags: {
        type: "notification-service"
      }
    )
  end
end
