# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_07_19_194527) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "ltree"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "accesses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "resource_type"
    t.uuid "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["resource_id"], name: "index_accesses_on_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_accesses_on_resource_type_and_resource_id"
    t.index ["user_id", "resource_id", "resource_type"], name: "index_accesses_on_user_id_and_resource_id_and_resource_type", unique: true
    t.index ["user_id"], name: "index_accesses_on_user_id"
  end

  create_table "addresses", id: :uuid, default: nil, force: :cascade do |t|
    t.string "street_address"
    t.string "village_or_colony"
    t.string "district"
    t.string "state"
    t.string "country"
    t.string "pin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "deleted_at"
    t.string "zone"
    t.index ["deleted_at"], name: "index_addresses_on_deleted_at"
    t.index ["zone"], name: "index_addresses_on_zone"
  end

  create_table "appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "patient_id", null: false
    t.uuid "facility_id", null: false
    t.date "scheduled_date", null: false
    t.string "status"
    t.string "cancel_reason"
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "remind_on"
    t.boolean "agreed_to_visit"
    t.datetime "deleted_at"
    t.string "appointment_type", null: false
    t.uuid "user_id"
    t.uuid "creation_facility_id"
    t.index ["appointment_type"], name: "index_appointments_on_appointment_type"
    t.index ["deleted_at"], name: "index_appointments_on_deleted_at"
    t.index ["facility_id"], name: "index_appointments_on_facility_id"
    t.index ["patient_id", "scheduled_date"], name: "index_appointments_on_patient_id_and_scheduled_date", order: { scheduled_date: :desc }
    t.index ["patient_id", "updated_at"], name: "index_appointments_on_patient_id_and_updated_at"
    t.index ["patient_id"], name: "index_appointments_on_patient_id"
    t.index ["updated_at"], name: "index_appointments_on_updated_at"
    t.index ["user_id"], name: "index_appointments_on_user_id"
  end

  create_table "blood_pressures", id: :uuid, default: nil, force: :cascade do |t|
    t.integer "systolic", null: false
    t.integer "diastolic", null: false
    t.uuid "patient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.uuid "facility_id", null: false
    t.uuid "user_id"
    t.datetime "deleted_at"
    t.datetime "recorded_at"
    t.index ["deleted_at"], name: "index_blood_pressures_on_deleted_at"
    t.index ["patient_id", "recorded_at"], name: "index_blood_pressures_on_patient_id_and_recorded_at", order: { recorded_at: :desc }
    t.index ["patient_id", "updated_at"], name: "index_blood_pressures_on_patient_id_and_updated_at"
    t.index ["patient_id"], name: "index_blood_pressures_on_patient_id"
    t.index ["recorded_at"], name: "index_blood_pressures_on_recorded_at"
    t.index ["updated_at"], name: "index_blood_pressures_on_updated_at"
    t.index ["user_id"], name: "index_blood_pressures_on_user_id"
  end

  create_table "blood_sugars", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "blood_sugar_type", null: false
    t.decimal "blood_sugar_value", null: false
    t.uuid "patient_id", null: false
    t.uuid "user_id", null: false
    t.uuid "facility_id", null: false
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "deleted_at"
    t.datetime "recorded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blood_sugar_type"], name: "index_blood_sugars_on_blood_sugar_type"
    t.index ["blood_sugar_value"], name: "index_blood_sugars_on_blood_sugar_value"
    t.index ["facility_id"], name: "index_blood_sugars_on_facility_id"
    t.index ["patient_id", "updated_at"], name: "index_blood_sugars_on_patient_id_and_updated_at"
    t.index ["patient_id"], name: "index_blood_sugars_on_patient_id"
    t.index ["updated_at"], name: "index_blood_sugars_on_updated_at"
    t.index ["user_id"], name: "index_blood_sugars_on_user_id"
  end

  create_table "call_logs", force: :cascade do |t|
    t.string "session_id"
    t.string "result"
    t.integer "duration"
    t.string "callee_phone_number", null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "caller_phone_number", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_call_logs_on_deleted_at"
  end

  create_table "communications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "appointment_id"
    t.uuid "user_id"
    t.string "communication_type"
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "detailable_type"
    t.bigint "detailable_id"
    t.uuid "notification_id"
    t.index ["appointment_id"], name: "index_communications_on_appointment_id"
    t.index ["deleted_at"], name: "index_communications_on_deleted_at"
    t.index ["detailable_type", "detailable_id"], name: "index_communications_on_detailable_type_and_detailable_id"
    t.index ["notification_id"], name: "index_communications_on_notification_id"
    t.index ["user_id"], name: "index_communications_on_user_id"
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "deduplication_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "record_type", null: false
    t.string "deleted_record_id", null: false
    t.string "deduped_record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at", "deleted_record_id"], name: "idx_deduplication_logs_lookup_deleted_at"
    t.index ["record_type", "deleted_record_id"], name: "idx_deduplication_logs_lookup_deleted_record", unique: true
    t.index ["user_id"], name: "index_deduplication_logs_on_user_id"
  end

  create_table "drug_stocks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "facility_id", null: false
    t.uuid "user_id", null: false
    t.uuid "protocol_drug_id", null: false
    t.integer "in_stock"
    t.integer "received"
    t.date "for_end_of_month", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "region_id"
    t.integer "redistributed"
    t.index ["facility_id"], name: "index_drug_stocks_on_facility_id"
    t.index ["protocol_drug_id"], name: "index_drug_stocks_on_protocol_drug_id"
    t.index ["user_id"], name: "index_drug_stocks_on_user_id"
  end

  create_table "email_authentications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.uuid "invited_by_id"
    t.string "invited_by_type"
    t.integer "invitations_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index "to_tsvector('simple'::regconfig, COALESCE((email)::text, ''::text))", name: "index_gin_email_authentications_on_email", using: :gin
    t.index ["deleted_at"], name: "index_email_authentications_on_deleted_at"
    t.index ["email"], name: "index_email_authentications_on_email", unique: true
    t.index ["invitation_token"], name: "index_email_authentications_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_email_authentications_on_invitations_count"
    t.index ["invited_by_id"], name: "index_email_authentications_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_email_authentications_invited_by"
    t.index ["reset_password_token"], name: "index_email_authentications_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_email_authentications_on_unlock_token", unique: true
  end

  create_table "encounters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "facility_id", null: false
    t.uuid "patient_id", null: false
    t.date "encountered_on", null: false
    t.integer "timezone_offset", null: false
    t.text "notes"
    t.jsonb "metadata"
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_encounters_on_deleted_at"
    t.index ["facility_id"], name: "index_encounters_on_facility_id"
    t.index ["patient_id", "updated_at"], name: "index_encounters_on_patient_id_and_updated_at"
    t.index ["patient_id"], name: "index_encounters_on_patient_id"
  end

  create_table "exotel_phone_number_details", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "patient_phone_number_id", null: false
    t.string "whitelist_status"
    t.datetime "whitelist_requested_at"
    t.datetime "whitelist_status_valid_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_exotel_phone_number_details_on_deleted_at"
    t.index ["patient_phone_number_id"], name: "index_exotel_phone_number_details_on_patient_phone_number_id"
    t.index ["patient_phone_number_id"], name: "index_unique_exotel_phone_number_details_on_phone_number_id", unique: true
    t.index ["whitelist_status"], name: "index_exotel_phone_number_details_on_whitelist_status"
  end

  create_table "experiments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "state", default: "new", null: false
    t.string "experiment_type", null: false
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_experiments_on_name", unique: true
  end

  create_table "facilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "street_address"
    t.string "village_or_colony"
    t.string "district"
    t.string "state"
    t.string "country"
    t.string "pin"
    t.string "facility_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.datetime "deleted_at"
    t.uuid "facility_group_id"
    t.string "slug"
    t.string "zone"
    t.boolean "enable_diabetes_management", default: false, null: false
    t.string "facility_size"
    t.integer "monthly_estimated_opd_load"
    t.boolean "enable_teleconsultation", default: false, null: false
    t.index "to_tsvector('simple'::regconfig, COALESCE((name)::text, ''::text))", name: "index_gin_facilities_on_name", using: :gin
    t.index "to_tsvector('simple'::regconfig, COALESCE((slug)::text, ''::text))", name: "index_gin_facilities_on_slug", using: :gin
    t.index ["deleted_at"], name: "index_facilities_on_deleted_at"
    t.index ["enable_diabetes_management"], name: "index_facilities_on_enable_diabetes_management"
    t.index ["facility_group_id"], name: "index_facilities_on_facility_group_id"
    t.index ["slug"], name: "index_facilities_on_slug", unique: true
    t.index ["updated_at"], name: "index_facilities_on_updated_at"
  end

  create_table "facilities_teleconsultation_medical_officers", id: false, force: :cascade do |t|
    t.uuid "facility_id", null: false
    t.uuid "user_id", null: false
    t.index ["facility_id", "user_id"], name: "index_facilities_teleconsult_mos_on_facility_id_and_user_id"
  end

  create_table "facility_business_identifiers", force: :cascade do |t|
    t.string "identifier", null: false
    t.string "identifier_type", null: false
    t.uuid "facility_id", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["facility_id", "identifier_type"], name: "index_facility_business_identifiers_on_facility_and_id_type", unique: true
    t.index ["facility_id"], name: "index_facility_business_identifiers_on_facility_id"
  end

  create_table "facility_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.uuid "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.uuid "protocol_id"
    t.string "slug"
    t.index ["deleted_at"], name: "index_facility_groups_on_deleted_at"
    t.index ["organization_id"], name: "index_facility_groups_on_organization_id"
    t.index ["protocol_id"], name: "index_facility_groups_on_protocol_id"
    t.index ["slug"], name: "index_facility_groups_on_slug", unique: true
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "imo_authorizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "patient_id", null: false
    t.datetime "last_invited_at", null: false
    t.string "status", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_imo_authorizations_on_patient_id"
  end

  create_table "medical_histories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "patient_id", null: false
    t.boolean "prior_heart_attack_boolean"
    t.boolean "prior_stroke_boolean"
    t.boolean "chronic_kidney_disease_boolean"
    t.boolean "receiving_treatment_for_hypertension_boolean"
    t.boolean "diabetes_boolean"
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "diagnosed_with_hypertension_boolean"
    t.text "prior_heart_attack"
    t.text "prior_stroke"
    t.text "chronic_kidney_disease"
    t.text "receiving_treatment_for_hypertension"
    t.text "diabetes"
    t.text "diagnosed_with_hypertension"
    t.datetime "deleted_at"
    t.uuid "user_id"
    t.text "hypertension"
    t.index ["deleted_at"], name: "index_medical_histories_on_deleted_at"
    t.index ["patient_id", "updated_at"], name: "index_medical_histories_on_patient_id_and_updated_at"
    t.index ["patient_id"], name: "index_medical_histories_on_patient_id"
    t.index ["user_id"], name: "index_medical_histories_on_user_id"
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "remind_on", null: false
    t.string "status", null: false
    t.string "message", null: false
    t.uuid "experiment_id"
    t.uuid "reminder_template_id"
    t.uuid "patient_id", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subject_type"
    t.uuid "subject_id"
    t.string "purpose", null: false
    t.index ["experiment_id"], name: "index_notifications_on_experiment_id"
    t.index ["patient_id"], name: "index_notifications_on_patient_id"
    t.index ["reminder_template_id"], name: "index_notifications_on_reminder_template_id"
    t.index ["subject_type", "subject_id"], name: "index_notifications_on_subject_type_and_subject_id"
  end

  create_table "observations", force: :cascade do |t|
    t.uuid "encounter_id", null: false
    t.uuid "user_id", null: false
    t.string "observable_type"
    t.uuid "observable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_observations_on_deleted_at"
    t.index ["encounter_id"], name: "index_observations_on_encounter_id"
    t.index ["observable_type", "observable_id"], name: "idx_observations_on_observable_type_and_id", unique: true
    t.index ["user_id"], name: "index_observations_on_user_id"
  end

  create_table "organizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "slug"
    t.index ["deleted_at"], name: "index_organizations_on_deleted_at"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "passport_authentications", force: :cascade do |t|
    t.string "access_token", null: false
    t.string "otp", null: false
    t.datetime "otp_expires_at", null: false
    t.uuid "patient_business_identifier_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "patient_business_identifiers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "identifier", null: false
    t.string "identifier_type", null: false
    t.uuid "patient_id", null: false
    t.string "metadata_version"
    t.json "metadata"
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_patient_business_identifiers_on_deleted_at"
    t.index ["identifier"], name: "index_patient_business_identifiers_identifier"
    t.index ["patient_id"], name: "index_patient_business_identifiers_on_patient_id"
  end

  create_table "patient_phone_numbers", id: :uuid, default: nil, force: :cascade do |t|
    t.string "number"
    t.string "phone_type"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "patient_id"
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "deleted_at"
    t.boolean "dnd_status", default: true, null: false
    t.index ["deleted_at"], name: "index_patient_phone_numbers_on_deleted_at"
    t.index ["dnd_status"], name: "index_patient_phone_numbers_on_dnd_status"
    t.index ["patient_id"], name: "index_patient_phone_numbers_on_patient_id"
  end

  create_table "patients", id: :uuid, default: nil, force: :cascade do |t|
    t.string "full_name"
    t.integer "age"
    t.string "gender"
    t.date "date_of_birth"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "address_id"
    t.datetime "age_updated_at"
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.boolean "test_data", default: false, null: false
    t.uuid "registration_facility_id"
    t.uuid "registration_user_id"
    t.datetime "deleted_at"
    t.boolean "contacted_by_counsellor", default: false
    t.string "could_not_contact_reason"
    t.datetime "recorded_at"
    t.string "reminder_consent", default: "denied", null: false
    t.uuid "deleted_by_user_id"
    t.string "deleted_reason"
    t.uuid "assigned_facility_id"
    t.index ["address_id"], name: "index_patients_on_address_id"
    t.index ["assigned_facility_id"], name: "index_patients_on_assigned_facility_id"
    t.index ["deleted_at"], name: "index_patients_on_deleted_at"
    t.index ["id", "updated_at"], name: "index_patients_on_id_and_updated_at"
    t.index ["recorded_at"], name: "index_patients_on_recorded_at"
    t.index ["registration_facility_id"], name: "index_patients_on_registration_facility_id"
    t.index ["registration_user_id"], name: "index_patients_on_registration_user_id"
    t.index ["reminder_consent"], name: "index_patients_on_reminder_consent"
    t.index ["updated_at"], name: "index_patients_on_updated_at"
  end

  create_table "phone_number_authentications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "phone_number", null: false
    t.string "password_digest", null: false
    t.string "otp", null: false
    t.datetime "otp_expires_at", null: false
    t.datetime "logged_in_at"
    t.string "access_token", null: false
    t.uuid "registration_facility_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.index "to_tsvector('simple'::regconfig, COALESCE((phone_number)::text, ''::text))", name: "index_gin_phone_number_authentications_on_phone_number", using: :gin
    t.index ["deleted_at"], name: "index_phone_number_authentications_on_deleted_at"
  end

  create_table "prescription_drugs", id: :uuid, default: nil, force: :cascade do |t|
    t.string "name", null: false
    t.string "rxnorm_code"
    t.string "dosage"
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "patient_id", null: false
    t.uuid "facility_id", null: false
    t.boolean "is_protocol_drug", null: false
    t.boolean "is_deleted", null: false
    t.datetime "deleted_at"
    t.uuid "user_id"
    t.string "frequency"
    t.integer "duration_in_days"
    t.uuid "teleconsultation_id"
    t.index ["deleted_at"], name: "index_prescription_drugs_on_deleted_at"
    t.index ["patient_id", "updated_at"], name: "index_prescription_drugs_on_patient_id_and_updated_at"
    t.index ["patient_id"], name: "index_prescription_drugs_on_patient_id"
    t.index ["teleconsultation_id"], name: "index_prescription_drugs_on_teleconsultation_id"
    t.index ["updated_at"], name: "index_prescription_drugs_on_updated_at"
    t.index ["user_id"], name: "index_prescription_drugs_on_user_id"
  end

  create_table "protocol_drugs", id: :uuid, default: nil, force: :cascade do |t|
    t.string "name", null: false
    t.string "dosage", null: false
    t.string "rxnorm_code"
    t.uuid "protocol_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "drug_category"
    t.boolean "stock_tracked", default: false, null: false
    t.index ["deleted_at"], name: "index_protocol_drugs_on_deleted_at"
  end

  create_table "protocols", id: :uuid, default: nil, force: :cascade do |t|
    t.string "name", null: false
    t.integer "follow_up_days"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_protocols_on_deleted_at"
    t.index ["updated_at"], name: "index_protocols_on_updated_at"
  end

  create_table "regions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "description"
    t.string "source_type"
    t.uuid "source_id"
    t.ltree "path"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "region_type", null: false
    t.index ["path"], name: "index_regions_on_path", using: :gist
    t.index ["path"], name: "index_regions_on_unique_path", unique: true
    t.index ["region_type"], name: "index_regions_on_region_type"
    t.index ["slug"], name: "index_regions_on_slug", unique: true
    t.index ["source_type", "source_id"], name: "index_regions_on_source_type_and_source_id"
  end

  create_table "reminder_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "message", null: false
    t.integer "remind_on_in_days", null: false
    t.uuid "treatment_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["treatment_group_id"], name: "index_reminder_templates_on_treatment_group_id"
  end

  create_table "teleconsultations", id: :uuid, default: nil, force: :cascade do |t|
    t.uuid "patient_id", null: false
    t.uuid "medical_officer_id", null: false
    t.uuid "requested_medical_officer_id"
    t.uuid "requester_id"
    t.uuid "facility_id"
    t.string "requester_completion_status"
    t.datetime "requested_at"
    t.datetime "recorded_at"
    t.string "teleconsultation_type"
    t.string "patient_took_medicines"
    t.string "patient_consented"
    t.string "medical_officer_number"
    t.datetime "deleted_at"
    t.datetime "device_updated_at"
    t.datetime "device_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["facility_id"], name: "index_teleconsultations_on_facility_id"
    t.index ["medical_officer_id"], name: "index_teleconsultations_on_medical_officer_id"
    t.index ["patient_id"], name: "index_teleconsultations_on_patient_id"
    t.index ["requested_medical_officer_id"], name: "index_teleconsultations_on_requested_medical_officer_id"
    t.index ["requester_id"], name: "index_teleconsultations_on_requester_id"
  end

  create_table "treatment_group_memberships", force: :cascade do |t|
    t.uuid "treatment_group_id", null: false
    t.uuid "patient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_treatment_group_memberships_on_patient_id"
    t.index ["treatment_group_id"], name: "index_treatment_group_memberships_on_treatment_group_id"
  end

  create_table "treatment_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "description", null: false
    t.uuid "experiment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["experiment_id"], name: "index_treatment_groups_on_experiment_id"
  end

  create_table "twilio_sms_delivery_details", force: :cascade do |t|
    t.string "session_id"
    t.string "result"
    t.string "callee_phone_number", null: false
    t.datetime "delivered_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_twilio_sms_delivery_details_on_deleted_at"
    t.index ["session_id"], name: "index_twilio_sms_delivery_details_on_session_id"
  end

  create_table "user_authentications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "authenticatable_type"
    t.uuid "authenticatable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["user_id", "authenticatable_type", "authenticatable_id"], name: "user_authentications_master_users_authenticatable_uniq_index", unique: true
    t.index ["user_id"], name: "index_user_authentications_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "full_name"
    t.string "sync_approval_status", null: false
    t.string "sync_approval_status_reason"
    t.datetime "device_updated_at", null: false
    t.datetime "device_created_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "role"
    t.uuid "organization_id"
    t.string "access_level"
    t.string "teleconsultation_phone_number"
    t.string "teleconsultation_isd_code"
    t.boolean "receive_approval_notifications", default: true, null: false
    t.index "to_tsvector('simple'::regconfig, COALESCE((full_name)::text, ''::text))", name: "index_gin_users_on_full_name", using: :gin
    t.index ["access_level"], name: "index_users_on_access_level"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["teleconsultation_phone_number"], name: "index_users_on_teleconsultation_phone_number"
  end

  add_foreign_key "accesses", "users"
  add_foreign_key "appointments", "facilities"
  add_foreign_key "blood_sugars", "facilities"
  add_foreign_key "blood_sugars", "users"
  add_foreign_key "communications", "notifications"
  add_foreign_key "drug_stocks", "facilities"
  add_foreign_key "drug_stocks", "protocol_drugs"
  add_foreign_key "drug_stocks", "users"
  add_foreign_key "encounters", "facilities"
  add_foreign_key "exotel_phone_number_details", "patient_phone_numbers"
  add_foreign_key "facilities", "facility_groups"
  add_foreign_key "facility_groups", "organizations"
  add_foreign_key "notifications", "experiments"
  add_foreign_key "notifications", "patients"
  add_foreign_key "notifications", "reminder_templates"
  add_foreign_key "observations", "encounters"
  add_foreign_key "observations", "users"
  add_foreign_key "patient_phone_numbers", "patients"
  add_foreign_key "patients", "addresses"
  add_foreign_key "patients", "facilities", column: "assigned_facility_id"
  add_foreign_key "patients", "facilities", column: "registration_facility_id"
  add_foreign_key "protocol_drugs", "protocols"
  add_foreign_key "reminder_templates", "treatment_groups"
  add_foreign_key "teleconsultations", "facilities"
  add_foreign_key "teleconsultations", "users", column: "medical_officer_id"
  add_foreign_key "teleconsultations", "users", column: "requested_medical_officer_id"
  add_foreign_key "teleconsultations", "users", column: "requester_id"
  add_foreign_key "treatment_group_memberships", "patients"
  add_foreign_key "treatment_group_memberships", "treatment_groups"
  add_foreign_key "treatment_groups", "experiments"

  create_view "patient_registrations_per_day_per_facilities", materialized: true, sql_definition: <<-SQL
      SELECT count(patients.id) AS registration_count,
      patients.registration_facility_id AS facility_id,
      timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, facilities.deleted_at)) AS deleted_at,
      (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text AS day,
      (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text AS month,
      (date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text AS quarter,
      (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text AS year
     FROM ((patients
       JOIN facilities ON ((patients.registration_facility_id = facilities.id)))
       JOIN medical_histories ON (((patients.id = medical_histories.patient_id) AND (medical_histories.hypertension = 'yes'::text))))
    WHERE (patients.deleted_at IS NULL)
    GROUP BY (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text, (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text, (date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text, patients.registration_facility_id, facilities.deleted_at;
  SQL
  add_index "patient_registrations_per_day_per_facilities", ["facility_id", "day", "year"], name: "index_patient_registrations_per_day_per_facilities", unique: true

  create_view "blood_pressures_per_facility_per_days", materialized: true, sql_definition: <<-SQL
      WITH latest_bp_per_patient_per_day AS (
           SELECT DISTINCT ON (blood_pressures.facility_id, blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text) blood_pressures.id AS bp_id,
              blood_pressures.facility_id,
              (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS day,
              (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS month,
              (date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS quarter,
              (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS year
             FROM (blood_pressures
               JOIN medical_histories ON (((blood_pressures.patient_id = medical_histories.patient_id) AND (medical_histories.hypertension = 'yes'::text))))
            WHERE (blood_pressures.deleted_at IS NULL)
            ORDER BY blood_pressures.facility_id, blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, blood_pressures.recorded_at DESC, blood_pressures.id
          )
   SELECT count(latest_bp_per_patient_per_day.bp_id) AS bp_count,
      facilities.id AS facility_id,
      timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, facilities.deleted_at)) AS deleted_at,
      latest_bp_per_patient_per_day.day,
      latest_bp_per_patient_per_day.month,
      latest_bp_per_patient_per_day.quarter,
      latest_bp_per_patient_per_day.year
     FROM (latest_bp_per_patient_per_day
       JOIN facilities ON ((facilities.id = latest_bp_per_patient_per_day.facility_id)))
    GROUP BY latest_bp_per_patient_per_day.day, latest_bp_per_patient_per_day.month, latest_bp_per_patient_per_day.quarter, latest_bp_per_patient_per_day.year, facilities.deleted_at, facilities.id;
  SQL
  add_index "blood_pressures_per_facility_per_days", ["facility_id", "day", "year"], name: "index_blood_pressures_per_facility_per_days", unique: true

  create_view "materialized_patient_summaries", materialized: true, sql_definition: <<-SQL
      SELECT p.recorded_at,
      concat(date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at))), ' Q', date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))) AS registration_quarter,
      p.full_name,
          CASE
              WHEN (p.date_of_birth IS NOT NULL) THEN date_part('year'::text, age((p.date_of_birth)::timestamp with time zone))
              ELSE floor(((p.age)::double precision + date_part('year'::text, age(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.age_updated_at))))))
          END AS current_age,
      p.gender,
      p.status,
      latest_phone_number.number AS latest_phone_number,
      addresses.village_or_colony,
      addresses.street_address,
      addresses.district,
      addresses.state,
      addresses.zone AS block,
      reg_facility.name AS registration_facility_name,
      reg_facility.facility_type AS registration_facility_type,
      reg_facility.district AS registration_district,
      reg_facility.state AS registration_state,
      p.assigned_facility_id,
      assigned_facility.name AS assigned_facility_name,
      assigned_facility.facility_type AS assigned_facility_type,
      assigned_facility.district AS assigned_facility_district,
      assigned_facility.state AS assigned_facility_state,
      latest_blood_pressure.systolic AS latest_blood_pressure_systolic,
      latest_blood_pressure.diastolic AS latest_blood_pressure_diastolic,
      latest_blood_pressure.recorded_at AS latest_blood_pressure_recorded_at,
      concat(date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, latest_blood_pressure.recorded_at))), ' Q', date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, latest_blood_pressure.recorded_at)))) AS latest_blood_pressure_quarter,
      latest_blood_pressure_facility.name AS latest_blood_pressure_facility_name,
      latest_blood_pressure_facility.facility_type AS latest_blood_pressure_facility_type,
      latest_blood_pressure_facility.district AS latest_blood_pressure_district,
      latest_blood_pressure_facility.state AS latest_blood_pressure_state,
      latest_blood_sugar.id AS latest_blood_sugar_id,
      latest_blood_sugar.blood_sugar_type AS latest_blood_sugar_type,
      latest_blood_sugar.blood_sugar_value AS latest_blood_sugar_value,
      latest_blood_sugar.recorded_at AS latest_blood_sugar_recorded_at,
      concat(date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, latest_blood_sugar.recorded_at))), ' Q', date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, latest_blood_sugar.recorded_at)))) AS latest_blood_sugar_quarter,
      latest_blood_sugar_facility.name AS latest_blood_sugar_facility_name,
      latest_blood_sugar_facility.facility_type AS latest_blood_sugar_facility_type,
      latest_blood_sugar_facility.district AS latest_blood_sugar_district,
      latest_blood_sugar_facility.state AS latest_blood_sugar_state,
      GREATEST((0)::double precision, date_part('day'::text, (now() - (next_scheduled_appointment.scheduled_date)::timestamp with time zone))) AS days_overdue,
      next_scheduled_appointment.id AS next_scheduled_appointment_id,
      next_scheduled_appointment.scheduled_date AS next_scheduled_appointment_scheduled_date,
      next_scheduled_appointment.status AS next_scheduled_appointment_status,
      next_scheduled_appointment.remind_on AS next_scheduled_appointment_remind_on,
      next_scheduled_appointment_facility.id AS next_scheduled_appointment_facility_id,
      next_scheduled_appointment_facility.name AS next_scheduled_appointment_facility_name,
      next_scheduled_appointment_facility.facility_type AS next_scheduled_appointment_facility_type,
      next_scheduled_appointment_facility.district AS next_scheduled_appointment_district,
      next_scheduled_appointment_facility.state AS next_scheduled_appointment_state,
          CASE
              WHEN (next_scheduled_appointment.scheduled_date IS NULL) THEN 0
              WHEN (next_scheduled_appointment.scheduled_date > date_trunc('day'::text, (now() - '30 days'::interval))) THEN 0
              WHEN ((latest_blood_pressure.systolic >= 180) OR (latest_blood_pressure.diastolic >= 110)) THEN 1
              WHEN (((mh.prior_heart_attack = 'yes'::text) OR (mh.prior_stroke = 'yes'::text)) AND ((latest_blood_pressure.systolic >= 140) OR (latest_blood_pressure.diastolic >= 90))) THEN 1
              WHEN ((((latest_blood_sugar.blood_sugar_type)::text = 'random'::text) AND (latest_blood_sugar.blood_sugar_value >= (300)::numeric)) OR (((latest_blood_sugar.blood_sugar_type)::text = 'post_prandial'::text) AND (latest_blood_sugar.blood_sugar_value >= (300)::numeric)) OR (((latest_blood_sugar.blood_sugar_type)::text = 'fasting'::text) AND (latest_blood_sugar.blood_sugar_value >= (200)::numeric)) OR (((latest_blood_sugar.blood_sugar_type)::text = 'hba1c'::text) AND (latest_blood_sugar.blood_sugar_value >= 9.0))) THEN 1
              ELSE 0
          END AS risk_level,
      latest_bp_passport.id AS latest_bp_passport_id,
      latest_bp_passport.identifier AS latest_bp_passport_identifier,
      mh.hypertension,
      mh.diabetes,
      p.id
     FROM ((((((((((((patients p
       LEFT JOIN addresses ON ((addresses.id = p.address_id)))
       LEFT JOIN facilities reg_facility ON ((reg_facility.id = p.registration_facility_id)))
       LEFT JOIN facilities assigned_facility ON ((assigned_facility.id = p.assigned_facility_id)))
       LEFT JOIN ( SELECT DISTINCT ON (medical_histories.patient_id) medical_histories.id,
              medical_histories.patient_id,
              medical_histories.prior_heart_attack_boolean,
              medical_histories.prior_stroke_boolean,
              medical_histories.chronic_kidney_disease_boolean,
              medical_histories.receiving_treatment_for_hypertension_boolean,
              medical_histories.diabetes_boolean,
              medical_histories.device_created_at,
              medical_histories.device_updated_at,
              medical_histories.created_at,
              medical_histories.updated_at,
              medical_histories.diagnosed_with_hypertension_boolean,
              medical_histories.prior_heart_attack,
              medical_histories.prior_stroke,
              medical_histories.chronic_kidney_disease,
              medical_histories.receiving_treatment_for_hypertension,
              medical_histories.diabetes,
              medical_histories.diagnosed_with_hypertension,
              medical_histories.deleted_at,
              medical_histories.user_id,
              medical_histories.hypertension
             FROM medical_histories
            WHERE (medical_histories.deleted_at IS NULL)) mh ON ((mh.patient_id = p.id)))
       LEFT JOIN ( SELECT DISTINCT ON (patient_phone_numbers.patient_id) patient_phone_numbers.id,
              patient_phone_numbers.number,
              patient_phone_numbers.phone_type,
              patient_phone_numbers.active,
              patient_phone_numbers.created_at,
              patient_phone_numbers.updated_at,
              patient_phone_numbers.patient_id,
              patient_phone_numbers.device_created_at,
              patient_phone_numbers.device_updated_at,
              patient_phone_numbers.deleted_at,
              patient_phone_numbers.dnd_status
             FROM patient_phone_numbers
            WHERE (patient_phone_numbers.deleted_at IS NULL)
            ORDER BY patient_phone_numbers.patient_id, patient_phone_numbers.device_created_at DESC) latest_phone_number ON ((latest_phone_number.patient_id = p.id)))
       LEFT JOIN ( SELECT DISTINCT ON (blood_pressures.patient_id) blood_pressures.id,
              blood_pressures.systolic,
              blood_pressures.diastolic,
              blood_pressures.patient_id,
              blood_pressures.created_at,
              blood_pressures.updated_at,
              blood_pressures.device_created_at,
              blood_pressures.device_updated_at,
              blood_pressures.facility_id,
              blood_pressures.user_id,
              blood_pressures.deleted_at,
              blood_pressures.recorded_at
             FROM blood_pressures
            WHERE (blood_pressures.deleted_at IS NULL)
            ORDER BY blood_pressures.patient_id, blood_pressures.recorded_at DESC) latest_blood_pressure ON ((latest_blood_pressure.patient_id = p.id)))
       LEFT JOIN facilities latest_blood_pressure_facility ON ((latest_blood_pressure_facility.id = latest_blood_pressure.facility_id)))
       LEFT JOIN ( SELECT DISTINCT ON (blood_sugars.patient_id) blood_sugars.id,
              blood_sugars.blood_sugar_type,
              blood_sugars.blood_sugar_value,
              blood_sugars.patient_id,
              blood_sugars.user_id,
              blood_sugars.facility_id,
              blood_sugars.device_created_at,
              blood_sugars.device_updated_at,
              blood_sugars.deleted_at,
              blood_sugars.recorded_at,
              blood_sugars.created_at,
              blood_sugars.updated_at
             FROM blood_sugars
            WHERE (blood_sugars.deleted_at IS NULL)
            ORDER BY blood_sugars.patient_id, blood_sugars.recorded_at DESC) latest_blood_sugar ON ((latest_blood_sugar.patient_id = p.id)))
       LEFT JOIN facilities latest_blood_sugar_facility ON ((latest_blood_sugar_facility.id = latest_blood_sugar.facility_id)))
       LEFT JOIN ( SELECT DISTINCT ON (patient_business_identifiers.patient_id) patient_business_identifiers.id,
              patient_business_identifiers.identifier,
              patient_business_identifiers.identifier_type,
              patient_business_identifiers.patient_id,
              patient_business_identifiers.metadata_version,
              patient_business_identifiers.metadata,
              patient_business_identifiers.device_created_at,
              patient_business_identifiers.device_updated_at,
              patient_business_identifiers.deleted_at,
              patient_business_identifiers.created_at,
              patient_business_identifiers.updated_at
             FROM patient_business_identifiers
            WHERE (((patient_business_identifiers.identifier_type)::text = 'simple_bp_passport'::text) AND (patient_business_identifiers.deleted_at IS NULL))
            ORDER BY patient_business_identifiers.patient_id, patient_business_identifiers.device_created_at DESC) latest_bp_passport ON ((latest_bp_passport.patient_id = p.id)))
       LEFT JOIN ( SELECT DISTINCT ON (appointments.patient_id) appointments.id,
              appointments.patient_id,
              appointments.facility_id,
              appointments.scheduled_date,
              appointments.status,
              appointments.cancel_reason,
              appointments.device_created_at,
              appointments.device_updated_at,
              appointments.created_at,
              appointments.updated_at,
              appointments.remind_on,
              appointments.agreed_to_visit,
              appointments.deleted_at,
              appointments.appointment_type,
              appointments.user_id,
              appointments.creation_facility_id
             FROM appointments
            WHERE (((appointments.status)::text = 'scheduled'::text) AND (appointments.deleted_at IS NULL))
            ORDER BY appointments.patient_id, appointments.scheduled_date DESC) next_scheduled_appointment ON ((next_scheduled_appointment.patient_id = p.id)))
       LEFT JOIN facilities next_scheduled_appointment_facility ON ((next_scheduled_appointment_facility.id = next_scheduled_appointment.facility_id)))
    WHERE (p.deleted_at IS NULL);
  SQL
  add_index "materialized_patient_summaries", ["id"], name: "index_materialized_patient_summaries_on_id", unique: true

  create_view "latest_blood_pressures_per_patient_per_months", materialized: true, sql_definition: <<-SQL
      SELECT DISTINCT ON (blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at))))::text, (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at))))::text) blood_pressures.id AS bp_id,
      blood_pressures.patient_id,
      patients.registration_facility_id,
      patients.assigned_facility_id,
      patients.status AS patient_status,
      blood_pressures.facility_id AS bp_facility_id,
      timezone('UTC'::text, timezone('UTC'::text, blood_pressures.recorded_at)) AS bp_recorded_at,
      timezone('UTC'::text, timezone('UTC'::text, patients.recorded_at)) AS patient_recorded_at,
      blood_pressures.systolic,
      blood_pressures.diastolic,
      timezone('UTC'::text, timezone('UTC'::text, blood_pressures.deleted_at)) AS deleted_at,
      medical_histories.hypertension AS medical_history_hypertension,
      (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at))))::text AS month,
      (date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at))))::text AS quarter,
      (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at))))::text AS year
     FROM ((blood_pressures
       JOIN patients ON ((patients.id = blood_pressures.patient_id)))
       LEFT JOIN medical_histories ON ((medical_histories.patient_id = blood_pressures.patient_id)))
    WHERE ((blood_pressures.deleted_at IS NULL) AND (patients.deleted_at IS NULL))
    ORDER BY blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at))))::text, (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at))))::text, blood_pressures.recorded_at DESC, blood_pressures.id;
  SQL
  add_index "latest_blood_pressures_per_patient_per_months", ["assigned_facility_id"], name: "index_bp_months_assigned_facility_id"
  add_index "latest_blood_pressures_per_patient_per_months", ["bp_id"], name: "index_latest_blood_pressures_per_patient_per_months", unique: true
  add_index "latest_blood_pressures_per_patient_per_months", ["bp_recorded_at"], name: "index_bp_months_bp_recorded_at"
  add_index "latest_blood_pressures_per_patient_per_months", ["medical_history_hypertension"], name: "index_bp_months_medical_history_hypertension"
  add_index "latest_blood_pressures_per_patient_per_months", ["patient_id"], name: "index_latest_bp_per_patient_per_months_patient_id"
  add_index "latest_blood_pressures_per_patient_per_months", ["patient_recorded_at"], name: "index_bp_months_patient_recorded_at"
  add_index "latest_blood_pressures_per_patient_per_months", ["registration_facility_id"], name: "index_bp_months_registration_facility_id"

  create_view "latest_blood_pressures_per_patient_per_quarters", materialized: true, sql_definition: <<-SQL
      SELECT DISTINCT ON (latest_blood_pressures_per_patient_per_months.patient_id, latest_blood_pressures_per_patient_per_months.year, latest_blood_pressures_per_patient_per_months.quarter) latest_blood_pressures_per_patient_per_months.bp_id,
      latest_blood_pressures_per_patient_per_months.patient_id,
      latest_blood_pressures_per_patient_per_months.registration_facility_id,
      latest_blood_pressures_per_patient_per_months.assigned_facility_id,
      latest_blood_pressures_per_patient_per_months.patient_status,
      latest_blood_pressures_per_patient_per_months.bp_facility_id,
      latest_blood_pressures_per_patient_per_months.bp_recorded_at,
      latest_blood_pressures_per_patient_per_months.patient_recorded_at,
      latest_blood_pressures_per_patient_per_months.systolic,
      latest_blood_pressures_per_patient_per_months.diastolic,
      latest_blood_pressures_per_patient_per_months.deleted_at,
      latest_blood_pressures_per_patient_per_months.medical_history_hypertension,
      latest_blood_pressures_per_patient_per_months.month,
      latest_blood_pressures_per_patient_per_months.quarter,
      latest_blood_pressures_per_patient_per_months.year
     FROM latest_blood_pressures_per_patient_per_months
    ORDER BY latest_blood_pressures_per_patient_per_months.patient_id, latest_blood_pressures_per_patient_per_months.year, latest_blood_pressures_per_patient_per_months.quarter, latest_blood_pressures_per_patient_per_months.bp_recorded_at DESC, latest_blood_pressures_per_patient_per_months.bp_id;
  SQL
  add_index "latest_blood_pressures_per_patient_per_quarters", ["bp_id"], name: "index_latest_blood_pressures_per_patient_per_quarters", unique: true
  add_index "latest_blood_pressures_per_patient_per_quarters", ["patient_id"], name: "index_latest_bp_per_patient_per_quarters_patient_id"

  create_view "latest_blood_pressures_per_patients", materialized: true, sql_definition: <<-SQL
      SELECT DISTINCT ON (latest_blood_pressures_per_patient_per_months.patient_id) latest_blood_pressures_per_patient_per_months.bp_id,
      latest_blood_pressures_per_patient_per_months.patient_id,
      latest_blood_pressures_per_patient_per_months.registration_facility_id,
      latest_blood_pressures_per_patient_per_months.assigned_facility_id,
      latest_blood_pressures_per_patient_per_months.patient_status,
      latest_blood_pressures_per_patient_per_months.bp_facility_id,
      latest_blood_pressures_per_patient_per_months.bp_recorded_at,
      latest_blood_pressures_per_patient_per_months.patient_recorded_at,
      latest_blood_pressures_per_patient_per_months.systolic,
      latest_blood_pressures_per_patient_per_months.diastolic,
      latest_blood_pressures_per_patient_per_months.deleted_at,
      latest_blood_pressures_per_patient_per_months.medical_history_hypertension,
      latest_blood_pressures_per_patient_per_months.month,
      latest_blood_pressures_per_patient_per_months.quarter,
      latest_blood_pressures_per_patient_per_months.year
     FROM latest_blood_pressures_per_patient_per_months
    ORDER BY latest_blood_pressures_per_patient_per_months.patient_id, latest_blood_pressures_per_patient_per_months.bp_recorded_at DESC, latest_blood_pressures_per_patient_per_months.bp_id;
  SQL
  add_index "latest_blood_pressures_per_patients", ["bp_id"], name: "index_latest_blood_pressures_per_patients", unique: true
  add_index "latest_blood_pressures_per_patients", ["patient_id"], name: "index_latest_bp_per_patient_patient_id"

  create_view "patient_summaries", sql_definition: <<-SQL
      SELECT p.recorded_at,
      concat(date_part('year'::text, p.recorded_at), ' Q', date_part('quarter'::text, p.recorded_at)) AS registration_quarter,
      p.full_name,
          CASE
              WHEN (p.date_of_birth IS NOT NULL) THEN date_part('year'::text, age((p.date_of_birth)::timestamp with time zone))
              ELSE ((p.age)::double precision + date_part('years'::text, age(now(), (p.age_updated_at)::timestamp with time zone)))
          END AS current_age,
      p.gender,
      p.status,
      p.assigned_facility_id,
      latest_phone_number.number AS latest_phone_number,
      addresses.village_or_colony,
      addresses.street_address,
      addresses.district,
      addresses.state,
      reg_facility.name AS registration_facility_name,
      reg_facility.facility_type AS registration_facility_type,
      reg_facility.district AS registration_district,
      reg_facility.state AS registration_state,
      latest_blood_pressure.systolic AS latest_blood_pressure_systolic,
      latest_blood_pressure.diastolic AS latest_blood_pressure_diastolic,
      latest_blood_pressure.recorded_at AS latest_blood_pressure_recorded_at,
      concat(date_part('year'::text, latest_blood_pressure.recorded_at), ' Q', date_part('quarter'::text, latest_blood_pressure.recorded_at)) AS latest_blood_pressure_quarter,
      latest_blood_pressure_facility.name AS latest_blood_pressure_facility_name,
      latest_blood_pressure_facility.facility_type AS latest_blood_pressure_facility_type,
      latest_blood_pressure_facility.district AS latest_blood_pressure_district,
      latest_blood_pressure_facility.state AS latest_blood_pressure_state,
      latest_blood_sugar.blood_sugar_type AS latest_blood_sugar_type,
      latest_blood_sugar.blood_sugar_value AS latest_blood_sugar_value,
      latest_blood_sugar.recorded_at AS latest_blood_sugar_recorded_at,
      concat(date_part('year'::text, latest_blood_sugar.recorded_at), ' Q', date_part('quarter'::text, latest_blood_sugar.recorded_at)) AS latest_blood_sugar_quarter,
      latest_blood_sugar_facility.name AS latest_blood_sugar_facility_name,
      latest_blood_sugar_facility.facility_type AS latest_blood_sugar_facility_type,
      latest_blood_sugar_facility.district AS latest_blood_sugar_district,
      latest_blood_sugar_facility.state AS latest_blood_sugar_state,
      GREATEST((0)::double precision, date_part('day'::text, (now() - (next_appointment.scheduled_date)::timestamp with time zone))) AS days_overdue,
      next_appointment.id AS next_appointment_id,
      next_appointment.scheduled_date AS next_appointment_scheduled_date,
      next_appointment.status AS next_appointment_status,
      next_appointment.cancel_reason AS next_appointment_cancel_reason,
      next_appointment.remind_on AS next_appointment_remind_on,
      next_appointment_facility.id AS next_appointment_facility_id,
      next_appointment_facility.name AS next_appointment_facility_name,
      next_appointment_facility.facility_type AS next_appointment_facility_type,
      next_appointment_facility.district AS next_appointment_district,
      next_appointment_facility.state AS next_appointment_state,
          CASE
              WHEN (next_appointment.scheduled_date IS NULL) THEN 0
              WHEN (next_appointment.scheduled_date > date_trunc('day'::text, (now() - '30 days'::interval))) THEN 0
              WHEN ((latest_blood_pressure.systolic >= 180) OR (latest_blood_pressure.diastolic >= 110)) THEN 1
              WHEN (((mh.prior_heart_attack = 'yes'::text) OR (mh.prior_stroke = 'yes'::text)) AND ((latest_blood_pressure.systolic >= 140) OR (latest_blood_pressure.diastolic >= 90))) THEN 1
              WHEN ((((latest_blood_sugar.blood_sugar_type)::text = 'random'::text) AND (latest_blood_sugar.blood_sugar_value >= (300)::numeric)) OR (((latest_blood_sugar.blood_sugar_type)::text = 'post_prandial'::text) AND (latest_blood_sugar.blood_sugar_value >= (300)::numeric)) OR (((latest_blood_sugar.blood_sugar_type)::text = 'fasting'::text) AND (latest_blood_sugar.blood_sugar_value >= (200)::numeric)) OR (((latest_blood_sugar.blood_sugar_type)::text = 'hba1c'::text) AND (latest_blood_sugar.blood_sugar_value >= 9.0))) THEN 1
              ELSE 0
          END AS risk_level,
      latest_bp_passport.identifier AS latest_bp_passport,
      p.id
     FROM (((((((((((patients p
       LEFT JOIN addresses ON ((addresses.id = p.address_id)))
       LEFT JOIN facilities reg_facility ON ((reg_facility.id = p.registration_facility_id)))
       LEFT JOIN medical_histories mh ON ((mh.patient_id = p.id)))
       LEFT JOIN ( SELECT DISTINCT ON (patient_phone_numbers.patient_id) patient_phone_numbers.id,
              patient_phone_numbers.number,
              patient_phone_numbers.phone_type,
              patient_phone_numbers.active,
              patient_phone_numbers.created_at,
              patient_phone_numbers.updated_at,
              patient_phone_numbers.patient_id,
              patient_phone_numbers.device_created_at,
              patient_phone_numbers.device_updated_at,
              patient_phone_numbers.deleted_at,
              patient_phone_numbers.dnd_status
             FROM patient_phone_numbers
            ORDER BY patient_phone_numbers.patient_id, patient_phone_numbers.device_created_at DESC) latest_phone_number ON ((latest_phone_number.patient_id = p.id)))
       LEFT JOIN ( SELECT DISTINCT ON (blood_pressures.patient_id) blood_pressures.id,
              blood_pressures.systolic,
              blood_pressures.diastolic,
              blood_pressures.patient_id,
              blood_pressures.created_at,
              blood_pressures.updated_at,
              blood_pressures.device_created_at,
              blood_pressures.device_updated_at,
              blood_pressures.facility_id,
              blood_pressures.user_id,
              blood_pressures.deleted_at,
              blood_pressures.recorded_at
             FROM blood_pressures
            ORDER BY blood_pressures.patient_id, blood_pressures.recorded_at DESC) latest_blood_pressure ON ((latest_blood_pressure.patient_id = p.id)))
       LEFT JOIN facilities latest_blood_pressure_facility ON ((latest_blood_pressure_facility.id = latest_blood_pressure.facility_id)))
       LEFT JOIN ( SELECT DISTINCT ON (blood_sugars.patient_id) blood_sugars.id,
              blood_sugars.blood_sugar_type,
              blood_sugars.blood_sugar_value,
              blood_sugars.patient_id,
              blood_sugars.user_id,
              blood_sugars.facility_id,
              blood_sugars.device_created_at,
              blood_sugars.device_updated_at,
              blood_sugars.deleted_at,
              blood_sugars.recorded_at,
              blood_sugars.created_at,
              blood_sugars.updated_at
             FROM blood_sugars
            ORDER BY blood_sugars.patient_id, blood_sugars.recorded_at DESC) latest_blood_sugar ON ((latest_blood_sugar.patient_id = p.id)))
       LEFT JOIN facilities latest_blood_sugar_facility ON ((latest_blood_sugar_facility.id = latest_blood_sugar.facility_id)))
       LEFT JOIN ( SELECT DISTINCT ON (patient_business_identifiers.patient_id) patient_business_identifiers.id,
              patient_business_identifiers.identifier,
              patient_business_identifiers.identifier_type,
              patient_business_identifiers.patient_id,
              patient_business_identifiers.metadata_version,
              patient_business_identifiers.metadata,
              patient_business_identifiers.device_created_at,
              patient_business_identifiers.device_updated_at,
              patient_business_identifiers.deleted_at,
              patient_business_identifiers.created_at,
              patient_business_identifiers.updated_at
             FROM patient_business_identifiers
            WHERE ((patient_business_identifiers.identifier_type)::text = 'simple_bp_passport'::text)
            ORDER BY patient_business_identifiers.patient_id, patient_business_identifiers.device_created_at DESC) latest_bp_passport ON ((latest_bp_passport.patient_id = p.id)))
       LEFT JOIN ( SELECT DISTINCT ON (appointments.patient_id) appointments.id,
              appointments.patient_id,
              appointments.facility_id,
              appointments.scheduled_date,
              appointments.status,
              appointments.cancel_reason,
              appointments.device_created_at,
              appointments.device_updated_at,
              appointments.created_at,
              appointments.updated_at,
              appointments.remind_on,
              appointments.agreed_to_visit,
              appointments.deleted_at,
              appointments.appointment_type,
              appointments.user_id,
              appointments.creation_facility_id
             FROM appointments
            ORDER BY appointments.patient_id, appointments.scheduled_date DESC) next_appointment ON ((next_appointment.patient_id = p.id)))
       LEFT JOIN facilities next_appointment_facility ON ((next_appointment_facility.id = next_appointment.facility_id)))
    WHERE (p.deleted_at IS NULL);
  SQL
  create_view "reporting_months", sql_definition: <<-SQL
      WITH month_dates AS (
           SELECT date(generate_series.generate_series) AS month_date
             FROM generate_series('2017-12-31 18:30:00+00'::timestamp with time zone, now(), '1 mon'::interval) generate_series(generate_series)
          )
   SELECT month_dates.month_date,
      date_part('month'::text, month_dates.month_date) AS month,
      date_part('quarter'::text, month_dates.month_date) AS quarter,
      date_part('year'::text, month_dates.month_date) AS year,
      to_char((month_dates.month_date)::timestamp with time zone, 'YYYY-MM'::text) AS month_string,
      to_char((month_dates.month_date)::timestamp with time zone, 'YYYY-Q'::text) AS quarter_string
     FROM month_dates;
  SQL
  create_view "reporting_facilities", sql_definition: <<-SQL
      SELECT facilities.id AS facility_id,
      facilities.name AS facility_name,
      facilities.facility_type,
      facilities.facility_size,
      facility_regions.id AS facility_region_id,
      facility_regions.name AS facility_region_name,
      facility_regions.slug AS facility_region_slug,
      block_regions.id AS block_region_id,
      block_regions.name AS block_name,
      block_regions.slug AS block_slug,
      district_regions.source_id AS district_id,
      district_regions.id AS district_region_id,
      district_regions.name AS district_name,
      district_regions.slug AS district_slug,
      state_regions.id AS state_region_id,
      state_regions.name AS state_name,
      state_regions.slug AS state_slug,
      org_regions.source_id AS organization_id,
      org_regions.id AS organization_region_id,
      org_regions.name AS organization_name,
      org_regions.slug AS organization_slug
     FROM (((((regions facility_regions
       JOIN facilities ON ((facilities.id = facility_regions.source_id)))
       JOIN regions block_regions ON ((block_regions.path = subpath(facility_regions.path, 0, '-1'::integer))))
       JOIN regions district_regions ON ((district_regions.path = subpath(block_regions.path, 0, '-1'::integer))))
       JOIN regions state_regions ON ((state_regions.path = subpath(district_regions.path, 0, '-1'::integer))))
       JOIN regions org_regions ON ((org_regions.path = subpath(state_regions.path, 0, '-1'::integer))))
    WHERE ((facility_regions.region_type)::text = 'facility'::text);
  SQL
  create_view "reporting_patient_blood_pressures", materialized: true, sql_definition: <<-SQL
      SELECT DISTINCT ON (bp.patient_id, cal.month_date) cal.month_date,
      cal.month,
      cal.quarter,
      cal.year,
      cal.month_string,
      cal.quarter_string,
      timezone('UTC'::text, timezone('UTC'::text, bp.recorded_at)) AS blood_pressure_recorded_at,
      bp.id AS blood_pressure_id,
      bp.patient_id,
      bp.systolic,
      bp.diastolic,
      bp.facility_id AS blood_pressure_facility_id,
      timezone('UTC'::text, timezone('UTC'::text, p.recorded_at)) AS patient_registered_at,
      p.assigned_facility_id AS patient_assigned_facility_id,
      p.registration_facility_id AS patient_registration_facility_id,
      (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))) * (12)::double precision) + (cal.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at))))) AS months_since_registration,
      (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))) * (4)::double precision) + (cal.month - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at))))) AS quarters_since_registration,
      (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at)))) * (12)::double precision) + (cal.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at))))) AS months_since_bp,
      (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at)))) * (4)::double precision) + (cal.quarter - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at))))) AS quarters_since_bp
     FROM ((blood_pressures bp
       LEFT JOIN reporting_months cal ON ((to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at)), 'YYYY-MM'::text) <= to_char((cal.month_date)::timestamp with time zone, 'YYYY-MM'::text))))
       JOIN patients p ON (((bp.patient_id = p.id) AND (p.deleted_at IS NULL))))
    WHERE (bp.deleted_at IS NULL)
    ORDER BY bp.patient_id, cal.month_date, bp.recorded_at DESC;
  SQL
  add_index "reporting_patient_blood_pressures", ["month_date", "patient_id"], name: "patient_blood_pressures_patient_id_month_date", unique: true

  create_view "reporting_patient_visits", materialized: true, sql_definition: <<-SQL
      SELECT DISTINCT ON (p.id, p.month_date) p.id AS patient_id,
      p.month_date,
      p.month,
      p.quarter,
      p.year,
      p.month_string,
      p.quarter_string,
      p.assigned_facility_id,
      p.registration_facility_id,
      timezone('UTC'::text, timezone('UTC'::text, p.recorded_at)) AS patient_recorded_at,
      e.id AS encounter_id,
      e.facility_id AS encounter_facility_id,
      timezone('UTC'::text, timezone('UTC'::text, e.recorded_at)) AS encounter_recorded_at,
      pd.id AS prescription_drug_id,
      pd.facility_id AS prescription_drug_facility_id,
      timezone('UTC'::text, timezone('UTC'::text, pd.recorded_at)) AS prescription_drug_recorded_at,
      app.id AS appointment_id,
      app.creation_facility_id AS appointment_creation_facility_id,
      timezone('UTC'::text, timezone('UTC'::text, app.recorded_at)) AS appointment_recorded_at,
      array_remove(ARRAY[
          CASE
              WHEN (to_char(e.recorded_at, 'YYYY-MM'::text) = p.month_string) THEN e.facility_id
              ELSE NULL::uuid
          END,
          CASE
              WHEN (to_char(pd.recorded_at, 'YYYY-MM'::text) = p.month_string) THEN pd.facility_id
              ELSE NULL::uuid
          END,
          CASE
              WHEN (to_char(app.recorded_at, 'YYYY-MM'::text) = p.month_string) THEN app.creation_facility_id
              ELSE NULL::uuid
          END], NULL::uuid) AS visited_facility_ids,
      timezone('UTC'::text, timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at))) AS visited_at,
      (((p.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p.recorded_at)))) * (12)::double precision) + (p.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p.recorded_at))))) AS months_since_registration,
      (((p.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p.recorded_at)))) * (4)::double precision) + (p.month - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p.recorded_at))))) AS quarters_since_registration,
      (((p.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at))))) * (12)::double precision) + (p.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at)))))) AS months_since_visit,
      (((p.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at))))) * (4)::double precision) + (p.month - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at)))))) AS quarters_since_visit
     FROM (((( SELECT p_1.id,
              p_1.full_name,
              p_1.age,
              p_1.gender,
              p_1.date_of_birth,
              p_1.status,
              p_1.created_at,
              p_1.updated_at,
              p_1.address_id,
              p_1.age_updated_at,
              p_1.device_created_at,
              p_1.device_updated_at,
              p_1.test_data,
              p_1.registration_facility_id,
              p_1.registration_user_id,
              p_1.deleted_at,
              p_1.contacted_by_counsellor,
              p_1.could_not_contact_reason,
              p_1.recorded_at,
              p_1.reminder_consent,
              p_1.deleted_by_user_id,
              p_1.deleted_reason,
              p_1.assigned_facility_id,
              cal.month_date,
              cal.month,
              cal.quarter,
              cal.year,
              cal.month_string,
              cal.quarter_string
             FROM (patients p_1
               LEFT JOIN reporting_months cal ON ((to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p_1.recorded_at)), 'YYYY-MM'::text) <= cal.month_string)))) p
       LEFT JOIN LATERAL ( SELECT timezone('UTC'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), (encounters.encountered_on)::timestamp without time zone)) AS recorded_at,
              encounters.id,
              encounters.facility_id,
              encounters.patient_id,
              encounters.encountered_on,
              encounters.timezone_offset,
              encounters.notes,
              encounters.metadata,
              encounters.device_created_at,
              encounters.device_updated_at,
              encounters.deleted_at,
              encounters.created_at,
              encounters.updated_at
             FROM encounters
            WHERE ((encounters.patient_id = p.id) AND (to_char((encounters.encountered_on)::timestamp with time zone, 'YYYY-MM'::text) <= p.month_string) AND (encounters.deleted_at IS NULL))
            ORDER BY encounters.encountered_on DESC
           LIMIT 1) e ON (true))
       LEFT JOIN LATERAL ( SELECT prescription_drugs.device_created_at AS recorded_at,
              prescription_drugs.id,
              prescription_drugs.name,
              prescription_drugs.rxnorm_code,
              prescription_drugs.dosage,
              prescription_drugs.device_created_at,
              prescription_drugs.device_updated_at,
              prescription_drugs.created_at,
              prescription_drugs.updated_at,
              prescription_drugs.patient_id,
              prescription_drugs.facility_id,
              prescription_drugs.is_protocol_drug,
              prescription_drugs.is_deleted,
              prescription_drugs.deleted_at,
              prescription_drugs.user_id,
              prescription_drugs.frequency,
              prescription_drugs.duration_in_days,
              prescription_drugs.teleconsultation_id
             FROM prescription_drugs
            WHERE ((prescription_drugs.patient_id = p.id) AND (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, prescription_drugs.device_created_at)), 'YYYY-MM'::text) <= p.month_string) AND (prescription_drugs.deleted_at IS NULL))
            ORDER BY prescription_drugs.device_created_at DESC
           LIMIT 1) pd ON (true))
       LEFT JOIN LATERAL ( SELECT appointments.device_created_at AS recorded_at,
              appointments.id,
              appointments.patient_id,
              appointments.facility_id,
              appointments.scheduled_date,
              appointments.status,
              appointments.cancel_reason,
              appointments.device_created_at,
              appointments.device_updated_at,
              appointments.created_at,
              appointments.updated_at,
              appointments.remind_on,
              appointments.agreed_to_visit,
              appointments.deleted_at,
              appointments.appointment_type,
              appointments.user_id,
              appointments.creation_facility_id
             FROM appointments
            WHERE ((appointments.patient_id = p.id) AND (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, appointments.device_created_at)), 'YYYY-MM'::text) <= p.month_string) AND (appointments.deleted_at IS NULL))
            ORDER BY appointments.device_created_at DESC
           LIMIT 1) app ON (true))
    WHERE (p.deleted_at IS NULL)
    ORDER BY p.id, p.month_date, (timezone('UTC'::text, timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at)))) DESC;
  SQL
  add_index "reporting_patient_visits", ["month_date", "patient_id"], name: "patient_visits_patient_id_month_date", unique: true

  create_view "reporting_patient_states", materialized: true, sql_definition: <<-SQL
      SELECT DISTINCT ON (p.id, cal.month_date) p.id AS patient_id,
      timezone('UTC'::text, timezone('UTC'::text, p.recorded_at)) AS recorded_at,
      p.status,
      p.gender,
      p.age,
      timezone('UTC'::text, timezone('UTC'::text, p.age_updated_at)) AS age_updated_at,
      p.date_of_birth,
      date_part('year'::text, COALESCE(age((p.date_of_birth)::timestamp with time zone), (make_interval(years => p.age) + age(p.age_updated_at)))) AS current_age,
      cal.month_date,
      cal.month,
      cal.quarter,
      cal.year,
      cal.month_string,
      cal.quarter_string,
      mh.hypertension,
      mh.prior_heart_attack,
      mh.prior_stroke,
      mh.chronic_kidney_disease,
      mh.receiving_treatment_for_hypertension,
      mh.diabetes,
      p.assigned_facility_id,
      assigned_facility.facility_size AS assigned_facility_size,
      assigned_facility.facility_type AS assigned_facility_type,
      assigned_facility.facility_region_slug AS assigned_facility_slug,
      assigned_facility.facility_region_id AS assigned_facility_region_id,
      assigned_facility.block_slug AS assigned_block_slug,
      assigned_facility.block_region_id AS assigned_block_region_id,
      assigned_facility.district_slug AS assigned_district_slug,
      assigned_facility.district_region_id AS assigned_district_region_id,
      assigned_facility.state_slug AS assigned_state_slug,
      assigned_facility.state_region_id AS assigned_state_region_id,
      assigned_facility.organization_slug AS assigned_organization_slug,
      assigned_facility.organization_region_id AS assigned_organization_region_id,
      p.registration_facility_id,
      registration_facility.facility_size AS registration_facility_size,
      registration_facility.facility_type AS registration_facility_type,
      registration_facility.facility_region_slug AS registration_facility_slug,
      registration_facility.facility_region_id AS registration_facility_region_id,
      registration_facility.block_slug AS registration_block_slug,
      registration_facility.block_region_id AS registration_block_region_id,
      registration_facility.district_slug AS registration_district_slug,
      registration_facility.district_region_id AS registration_district_region_id,
      registration_facility.state_slug AS registration_state_slug,
      registration_facility.state_region_id AS registration_state_region_id,
      registration_facility.organization_slug AS registration_organization_slug,
      registration_facility.organization_region_id AS registration_organization_region_id,
      bps.blood_pressure_id,
      bps.blood_pressure_facility_id AS bp_facility_id,
      bps.blood_pressure_recorded_at AS bp_recorded_at,
      bps.systolic,
      bps.diastolic,
      visits.encounter_id,
      visits.encounter_recorded_at,
      visits.prescription_drug_id,
      visits.prescription_drug_recorded_at,
      visits.appointment_id,
      visits.appointment_recorded_at,
      visits.visited_facility_ids,
      (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))) * (12)::double precision) + (cal.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at))))) AS months_since_registration,
      (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))) * (4)::double precision) + (cal.month - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at))))) AS quarters_since_registration,
      visits.months_since_visit,
      visits.quarters_since_visit,
      bps.months_since_bp,
      bps.quarters_since_bp,
          CASE
              WHEN ((bps.systolic IS NULL) OR (bps.diastolic IS NULL)) THEN 'unknown'::text
              WHEN ((bps.systolic < 140) AND (bps.diastolic < 90)) THEN 'controlled'::text
              ELSE 'uncontrolled'::text
          END AS last_bp_state,
          CASE
              WHEN ((p.status)::text = 'dead'::text) THEN 'dead'::text
              WHEN (((((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))) * (12)::double precision) + (cal.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at))))) < (12)::double precision) OR (bps.months_since_bp < (12)::double precision)) THEN 'under_care'::text
              ELSE 'lost_to_follow_up'::text
          END AS htn_care_state,
          CASE
              WHEN ((visits.months_since_visit >= (3)::double precision) OR (visits.months_since_visit IS NULL)) THEN 'missed_visit'::text
              WHEN ((bps.months_since_bp >= (3)::double precision) OR (bps.months_since_bp IS NULL)) THEN 'visited_no_bp'::text
              WHEN ((bps.systolic < 140) AND (bps.diastolic < 90)) THEN 'controlled'::text
              ELSE 'uncontrolled'::text
          END AS htn_treatment_outcome_in_last_3_months,
          CASE
              WHEN ((visits.months_since_visit >= (2)::double precision) OR (visits.months_since_visit IS NULL)) THEN 'missed_visit'::text
              WHEN ((bps.months_since_bp >= (2)::double precision) OR (bps.months_since_bp IS NULL)) THEN 'visited_no_bp'::text
              WHEN ((bps.systolic < 140) AND (bps.diastolic < 90)) THEN 'controlled'::text
              ELSE 'uncontrolled'::text
          END AS htn_treatment_outcome_in_last_2_months,
          CASE
              WHEN ((visits.quarters_since_visit >= (1)::double precision) OR (visits.quarters_since_visit IS NULL)) THEN 'missed_visit'::text
              WHEN ((bps.quarters_since_bp >= (1)::double precision) OR (bps.quarters_since_bp IS NULL)) THEN 'visited_no_bp'::text
              WHEN ((bps.systolic < 140) AND (bps.diastolic < 90)) THEN 'controlled'::text
              ELSE 'uncontrolled'::text
          END AS htn_treatment_outcome_in_quarter
     FROM ((((((patients p
       LEFT JOIN reporting_months cal ON ((to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)), 'YYYY-MM'::text) <= to_char((cal.month_date)::timestamp with time zone, 'YYYY-MM'::text))))
       LEFT JOIN reporting_patient_blood_pressures bps ON (((p.id = bps.patient_id) AND (cal.month = bps.month) AND (cal.year = bps.year))))
       LEFT JOIN reporting_patient_visits visits ON (((p.id = visits.patient_id) AND (cal.month = visits.month) AND (cal.year = visits.year))))
       LEFT JOIN medical_histories mh ON (((p.id = mh.patient_id) AND (mh.deleted_at IS NULL))))
       JOIN reporting_facilities registration_facility ON ((registration_facility.facility_id = p.registration_facility_id)))
       JOIN reporting_facilities assigned_facility ON ((assigned_facility.facility_id = p.assigned_facility_id)))
    WHERE (p.deleted_at IS NULL)
    ORDER BY p.id, cal.month_date;
  SQL
  add_index "reporting_patient_states", ["assigned_block_region_id"], name: "patient_states_assigned_block"
  add_index "reporting_patient_states", ["assigned_district_region_id"], name: "patient_states_assigned_district"
  add_index "reporting_patient_states", ["assigned_facility_region_id"], name: "patient_states_assigned_facility"
  add_index "reporting_patient_states", ["assigned_state_region_id"], name: "patient_states_assigned_state"
  add_index "reporting_patient_states", ["hypertension", "htn_care_state", "htn_treatment_outcome_in_last_3_months"], name: "patient_states_care_state"
  add_index "reporting_patient_states", ["month_date", "patient_id"], name: "patient_states_month_date_patient_id", unique: true

  create_view "reporting_facility_states", materialized: true, sql_definition: <<-SQL
      WITH registered_patients AS (
           SELECT reporting_patient_states.registration_facility_region_id AS region_id,
              reporting_patient_states.month_date,
              count(*) AS cumulative_registrations,
              count(*) FILTER (WHERE (reporting_patient_states.months_since_registration = (0)::double precision)) AS monthly_registrations
             FROM reporting_patient_states
            WHERE (reporting_patient_states.hypertension = 'yes'::text)
            GROUP BY reporting_patient_states.registration_facility_region_id, reporting_patient_states.month_date
          ), assigned_patients AS (
           SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
              reporting_patient_states.month_date,
              count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'under_care'::text)) AS under_care,
              count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text)) AS lost_to_follow_up,
              count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'dead'::text)) AS dead,
              count(*) AS assigned_patients
             FROM reporting_patient_states
            WHERE (reporting_patient_states.hypertension = 'yes'::text)
            GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.month_date
          ), treatment_outcomes_in_last_3_months AS (
           SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
              reporting_patient_states.month_date,
              count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'controlled'::text) AND (reporting_patient_states.htn_care_state = 'under_care'::text))) AS controlled_under_care,
              count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'controlled'::text) AND (reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text))) AS controlled_lost_to_follow_up,
              count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'uncontrolled'::text) AND (reporting_patient_states.htn_care_state = 'under_care'::text))) AS uncontrolled_under_care,
              count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'uncontrolled'::text) AND (reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text))) AS uncontrolled_lost_to_follow_up,
              count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'missed_visit'::text) AND (reporting_patient_states.htn_care_state = 'under_care'::text))) AS missed_visit_under_care,
              count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'missed_visit'::text) AND (reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text))) AS missed_visit_lost_to_follow_up,
              count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'visited_no_bp'::text) AND (reporting_patient_states.htn_care_state = 'under_care'::text))) AS visited_no_bp_under_care,
              count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'visited_no_bp'::text) AND (reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text))) AS visited_no_bp_lost_to_follow_up,
              count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'under_care'::text)) AS patients_under_care,
              count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text)) AS patients_lost_to_follow_up
             FROM reporting_patient_states
            WHERE ((reporting_patient_states.hypertension = 'yes'::text) AND (reporting_patient_states.months_since_registration >= (3)::double precision))
            GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.month_date
          )
   SELECT cal.month_date,
      cal.month,
      cal.quarter,
      cal.year,
      cal.month_string,
      cal.quarter_string,
      rf.facility_id,
      rf.facility_name,
      rf.facility_type,
      rf.facility_size,
      rf.facility_region_id,
      rf.facility_region_name,
      rf.facility_region_slug,
      rf.block_region_id,
      rf.block_name,
      rf.block_slug,
      rf.district_id,
      rf.district_region_id,
      rf.district_name,
      rf.district_slug,
      rf.state_region_id,
      rf.state_name,
      rf.state_slug,
      rf.organization_id,
      rf.organization_region_id,
      rf.organization_name,
      rf.organization_slug,
      rp.cumulative_registrations,
      rp.monthly_registrations,
      ap.under_care,
      ap.lost_to_follow_up,
      ap.dead,
      ap.assigned_patients,
      tout.controlled_under_care,
      tout.controlled_lost_to_follow_up,
      tout.uncontrolled_under_care,
      tout.uncontrolled_lost_to_follow_up,
      tout.missed_visit_under_care,
      tout.missed_visit_lost_to_follow_up,
      tout.visited_no_bp_under_care,
      tout.visited_no_bp_lost_to_follow_up,
      tout.patients_under_care,
      tout.patients_lost_to_follow_up
     FROM ((((registered_patients rp
       LEFT JOIN assigned_patients ap ON (((rp.region_id = ap.region_id) AND (rp.month_date = ap.month_date))))
       LEFT JOIN treatment_outcomes_in_last_3_months tout ON (((rp.region_id = tout.region_id) AND (rp.month_date = tout.month_date))))
       JOIN reporting_facilities rf ON ((rp.region_id = rf.facility_region_id)))
       JOIN reporting_months cal ON ((rp.month_date = cal.month_date)));
  SQL
  add_index "reporting_facility_states", ["month_date", "facility_region_id"], name: "facility_states_month_date_region_id", unique: true

end
