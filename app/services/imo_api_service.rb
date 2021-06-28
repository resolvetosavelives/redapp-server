class ImoApiService
  IMO_USERNAME = ENV["IMO_USERNAME"]
  IMO_PASSWORD = ENV["IMO_PASSWORD"]
  BASE_URL = "https://sgp.imo.im/api/simple/".freeze

  class Error < StandardError
    attr_reader :path, :response, :exception_message
    def initialize(message, path: nil, response: nil, exception_message: nil)
      super(message)
      @path = path
      @response = response
      @exception_message = exception_message
    end
  end

  attr_reader :patient

  def initialize(patient)
    @patient = patient
  end

  def invite
    return unless Flipper.enabled?(:imo_messaging)

    Statsd.instance.increment("imo.invites.attempt")
    url = BASE_URL + "send_invite"
    request_body = JSON(
      phone: patient.latest_mobile_number,
      msg: invitation_message,
      contents: [{key: "Name", value: patient.full_name}, {key: "Notes", value: invitation_message}],
      title: "Invitation",
      action: "Click here"
    )
    response = execute_post(url, body: request_body)
    process_response(response, url)
  end

  private

  def execute_post(url, data)
    HTTP
      .basic_auth(user: IMO_USERNAME, pass: IMO_PASSWORD)
      .post(url, data)
  rescue HTTP::Error => e
    raise Error.new("Error while calling the IMO API", path: url, exception_message: e)
  end

  def process_response(response, url)
    case response.status
    when 200 then :invited
    when 400
      if JSON.parse(response.body).dig("response", "type") == "nonexistent_user"
        Statsd.instance.increment("imo.invites.no_imo_account")
        :no_imo_account
      else
        Statsd.instance.increment("imo.invites.error")
        raise Error.new("Unknown 400 error from IMO", path: url, response: response)
      end
    else
      Statsd.instance.increment("imo.invites.error")
      raise Error.new("Unknown response error from IMO", path: url, response: response)
    end
  end

  def invitation_message
    "This will need to be a localized string"
  end
end
