class Api::Current::ExotelCallSessionsController < ApplicationController
  SCHEDULE_CALL_LOG_JOB_AFTER = 30.minutes

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
      schedule_call_log_job(session.user.id, session.patient_phone_number.number)

      respond_in_plain_text(:ok)
    else
      respond_in_plain_text(:not_found)
    end
  end

  private

  def call_status
    (params[:CallStatus] || params[:DialCallStatus]).underscore
  end

  def call_type
    params[:CallType].underscore
  end

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
    NewRelic::Agent.increment_metric("#{controller_name}/call_type/#{call_type}")
    NewRelic::Agent.increment_metric("#{controller_name}/call_status/#{call_status}")
  end

  def schedule_call_log_job(user_id, callee_phone_number)
    ExotelCallDetailsJob
      .set(wait: SCHEDULE_CALL_LOG_JOB_AFTER)
      .perform_later(params[:CallSid],
                     user_id,
                     callee_phone_number,
                     call_status)
  end
end
