class CallSession
  EXPIRE_CALL_SESSION_IN_SECONDS = 1.day.seconds.to_i

  attr_reader :user, :patient_phone_number

  def initialize(call_id, user_phone_number, patient_phone_number)
    @call_id = call_id
    @user = User.find_by_phone_number(sanitized_phone_number(user_phone_number))
    @patient_phone_number = PatientPhoneNumber.find_by_number(patient_phone_number)
  end

  def authorized?
    user.present? &&
      user.sync_approval_status_allowed? &&
      patient_phone_number.present? &&
      user.phone_number != patient_phone_number.number
  end

  def save
    CallSessionStore::CONNECTION_POOL.with do |connection|
      RedisService
        .new(connection)
        .hmset_with_expiry(CallSession.session_key(@call_id),
                           session_data,
                           EXPIRE_CALL_SESSION_IN_SECONDS)
    end
  end

  def kill
    CallSessionStore::CONNECTION_POOL.with do |connection|
      RedisService
        .new(connection)
        .del(CallSession.session_key(@call_id))
    end
  end

  class << self
    def fetch(call_id)
      data = CallSessionStore::CONNECTION_POOL.with do |connection|
        RedisService
          .new(connection)
          .hgetall(session_key(call_id))
      end

      CallSession.new(call_id,
                      data[:user_phone_number],
                      data[:patient_phone_number]) if data.present?
    end

    def session_key(call_id)
      [self.name, call_id].join('/')
    end
  end

  private

  def sanitized_phone_number(phone_number)
    Phonelib.parse(phone_number, ENV['DEFAULT_COUNTRY'] || 'IN').raw_national
  end

  def session_data
    { patient_phone_number: patient_phone_number.number,
      user_phone_number: user.phone_number }
  end
end
