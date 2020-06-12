module Api::V3::SyncToUser
  extend ActiveSupport::Concern
  included do
    def facility_group_records
      current_facility_group
        .send(model_name.name.underscore.pluralize.to_sym)
        .with_discarded
    end

    def current_facility_records
      []
    end

    def other_facility_records
      other_facilities_limit = limit - current_facility_records.count
      model_name
        .with_discarded
        .updated_on_server_since(other_facilities_processed_since, other_facilities_limit)
    end

    private

    def records_to_sync
      current_facility_records + other_facility_records
    end

    def processed_until(records)
      records.last.updated_at.strftime(APIController::TIME_WITHOUT_TIMEZONE_FORMAT) if records.present?
    end

    def response_process_token
      {current_facility_id: current_facility.id,
       current_facility_processed_since: processed_until(current_facility_records) || current_facility_processed_since,
       other_facilities_processed_since: processed_until(other_facility_records) || other_facilities_processed_since,
       resync_token: resync_token}
    end

    def encode_process_token(process_token)
      Base64.encode64(process_token.to_json)
    end

    def other_facilities_processed_since
      return Time.new(0) if force_resync?
      process_token[:other_facilities_processed_since].try(:to_time) || Time.new(0)
    end

    def current_facility_processed_since
      if force_resync?
        Time.new(0)
      elsif process_token[:current_facility_processed_since].blank?
        other_facilities_processed_since
      elsif process_token[:current_facility_id] != current_facility.id
        [process_token[:current_facility_processed_since].to_time,
          other_facilities_processed_since].min
      else
        process_token[:current_facility_processed_since].to_time
      end
    end

    def force_resync?
      process_token[:resync_token] != resync_token
    end

    def resync_token
      request.headers["HTTP_X_RESYNC_TOKEN"]
    end
  end
end
