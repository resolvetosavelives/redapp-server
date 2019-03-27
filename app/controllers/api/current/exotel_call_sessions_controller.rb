class Api::Current::ExotelCallSessionsController < ApplicationController
  after_action :report_http_status

  def create
    unless valid_patient_phone_number?
      respond_in_plain_text(:bad_request) and return
    end

    session = CallSession.new(params[:CallSid], params[:From], parse_patient_phone_number)
    if session.authorized?
      session.save
      respond_in_plain_text(:ok)
    else
      respond_in_plain_text(:forbidden)
    end
  end

  def fetch
    session = CallSession.fetch(params[:CallSid])

    if session.present?
      respond_in_plain_text(:ok, session.patient_phone_number.number)
    else
      respond_in_plain_text(:not_found)
    end
  end

  def terminate
    session = CallSession.fetch(params[:CallSid])

    if session.present?
      session.kill
      report_call_info
      respond_in_plain_text(:ok)
    else
      respond_in_plain_text(:not_found)
    end
  end

  private

  def parse_patient_phone_number
    params[:digits].tr('"', '')
  end

  def valid_patient_phone_number?
    parse_patient_phone_number.scan(/\D/).empty?
  end

  def respond_in_plain_text(status, text = '')
    render plain: text, status: status
  end

  def report_http_status
    NewRelic::Agent.increment_metric("#{controller_name}/#{action_name}/#{response.status}")
  end

  def report_call_info
    NewRelic::Agent.record_metric("#{controller_name}/call_duration", params[:DialCallDuration].to_i)
    NewRelic::Agent.increment_metric("#{controller_name}/call_type/#{params[:CallType]}")
  end
end
