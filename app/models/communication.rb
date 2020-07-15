class Communication < ApplicationRecord
  include Mergeable
  include Hashable

  belongs_to :appointment
  belongs_to :user, optional: true
  belongs_to :detailable, polymorphic: true, optional: true

  delegate :unsuccessful?, :successful?, :in_progress?, to: :detailable

  enum communication_type: {
    voip_call: "voip_call",
    manual_call: "manual_call",
    missed_visit_sms_reminder: "missed_visit_sms_reminder",
    missed_visit_whatsapp_reminder: "missed_visit_whatsapp_reminder"
  }

  COMMUNICATION_RESULTS = {
    unavailable: "unavailable",
    unreachable: "unreachable",
    successful: "successful",
    unsuccessful: "unsuccessful",
    in_progress: "in_progress",
    unknown: "unknown"
  }

  ANONYMIZED_DATA_FIELDS = %w[id appointment_id patient_id user_id created_at communication_type
    communication_result]

  DEFAULT_MESSAGING_START_HOUR = 14
  DEFAULT_MESSAGING_END_HOUR = 16

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  def self.latest_by_type(communication_type)
    send(communication_type).order(device_created_at: :desc).first
  end

  def self.create_with_twilio_details!(appointment:, twilio_sid:, twilio_msg_status:, communication_type:)
    transaction do
      sms_delivery_details =
        TwilioSmsDeliveryDetail.create!(session_id: twilio_sid,
                                        result: twilio_msg_status,
                                        callee_phone_number: appointment.patient.latest_mobile_number)
      Communication.create!(communication_type: communication_type,
                            detailable: sms_delivery_details,
                            appointment: appointment,
                            device_created_at: DateTime.current,
                            device_updated_at: DateTime.current)
    end
  end

  def self.messaging_start_hour
    @messaging_start_hour ||= ENV.fetch("APPOINTMENT_NOTIFICATION_HOUR_OF_DAY_START", DEFAULT_MESSAGING_START_HOUR).to_i
  end

  def self.messaging_end_hour
    @messaging_end_hour ||= ENV.fetch("APPOINTMENT_NOTIFICATION_HOUR_OF_DAY_FINISH", DEFAULT_MESSAGING_END_HOUR).to_i
  end

  def self.next_messaging_time
    now = DateTime.now.in_time_zone(Rails.application.config.country[:time_zone])

    if now.hour < messaging_start_hour
      now.change(hour: messaging_start_hour)
    elsif now.hour >= messaging_end_hour
      now.change(hour: messaging_start_hour).advance(days: 1)
    else
      now
    end
  end

  def communication_result
    if successful?
      COMMUNICATION_RESULTS[:successful]
    elsif unsuccessful?
      COMMUNICATION_RESULTS[:unsuccessful]
    elsif in_progress?
      COMMUNICATION_RESULTS[:in_progress]
    else
      COMMUNICATION_RESULTS[:unknown]
    end
  end

  def attempted?
    successful? || in_progress?
  end

  def anonymized_data
    {id: hash_uuid(id),
     appointment_id: hash_uuid(appointment_id),
     patient_id: hash_uuid(appointment.patient_id),
     user_id: hash_uuid(user_id),
     created_at: created_at,
     communication_type: communication_type,
     communication_result: communication_result}
  end
end
