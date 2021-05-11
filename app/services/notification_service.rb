class NotificationService
  DEFAULT_LOCALE = :en

  attr_reader :response, :error
  def client
    @client ||= Twilio::REST::Client.new(twilio_account_sid, twilio_auth_token)
  end

  def send_sms(recipient_number, message, callback_url = nil)
    sender_number = twilio_sender_number
    recipient_number = parse_phone_number(recipient_number)

    send_twilio_message(sender_number, recipient_number, message, callback_url)
  end

  def send_whatsapp(recipient_number, message, callback_url = nil)
    sender_number = "whatsapp:" + twilio_sender_number
    recipient_number = "whatsapp:" + parse_phone_number(recipient_number)

    send_twilio_message(sender_number, recipient_number, message, callback_url)
  end

  def parse_phone_number(number)
    parsed_number = Phonelib.parse(number, Rails.application.config.country[:abbreviation]).raw_national
    default_country_code + parsed_number
  end

  def failed?
    !error.nil?
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
  rescue Twilio::REST::TwilioError => e
    report_error(e)
    @error = :exception
  end

  def twilio_account_sid
    ENV.fetch("TWILIO_ACCOUNT_SID")
  end

  def twilio_auth_token
    ENV.fetch("TWILIO_AUTH_TOKEN")
  end

  def twilio_sender_number
    ENV.fetch("TWILIO_PHONE_NUMBER")
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
