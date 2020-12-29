module Api::V3::SyncToUser
  extend ActiveSupport::Concern

  included do
    def current_facility_records
      Statsd.instance.time("current_facility_records.#{model.name}") do
        @current_facility_records ||=
          model_sync_scope
            .where(patient: current_facility.prioritized_patients.select(:id))
            .updated_on_server_since(current_facility_processed_since, limit)
      end
    end

    def other_facility_records
      Statsd.instance.time("other_facility_records.#{model.name}") do
        other_facilities_limit = limit - current_facility_records.size

        @other_facility_records ||=
          model_sync_scope
            .where("patient_id = ANY (array(?))",
              current_sync_region
                .syncable_patients
                .where.not(registration_facility: current_facility)
                .select(:id))
            .updated_on_server_since(other_facilities_processed_since, other_facilities_limit)
      end
    end

    private

    def model_sync_scope
      controller_name.classify.constantize.for_sync

    def records_to_sync
      Statsd.instance.time("records_to_sync.#{model.name}") do
        current_facility_records + other_facility_records
      end
    end

    def processed_until(records)
      records.last.updated_at.strftime(APIController::TIME_WITHOUT_TIMEZONE_FORMAT) if records.any?
    end

    def response_process_token
      {
        current_facility_id: current_facility.id,
        current_facility_processed_since: processed_until(current_facility_records) || current_facility_processed_since,
        other_facilities_processed_since: processed_until(other_facility_records) || other_facilities_processed_since,
        resync_token: resync_token,
        sync_region_id: current_sync_region.id
      }
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
      resync_token_modified? || sync_region_modified?
    end

    def resync_token_modified?
      process_token[:resync_token] != resync_token
    end

    def sync_region_modified?
      return unless current_user.feature_enabled?(:block_level_sync)
      return if requested_sync_region_id.blank?
      return if process_token[:sync_region_id].blank?
      process_token[:sync_region_id] != requested_sync_region_id
    end
  end
end
