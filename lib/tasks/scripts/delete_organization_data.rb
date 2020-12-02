class DeleteOrganizationData
  include Memery

  def self.delete_path_data(path_org_id, dry_run: false)
    # Narrowing down by facility_type is the only way to
    # distinguish between soft deleted facilities from IHCI and PATH
    facilities =
      Facility
        .with_discarded
        .where(facility_group_id: nil)
        .where("facility_type = 'Standalone' OR facility_type = 'Hospital'")

    new(organization_id: path_org_id, facilities: facilities, dry_run: dry_run).delete_path_data
  end

  def delete_path_data
    # if !SimpleServer.env.production? || CountryConfig.current[:name] != "India"
    #   Rails.logger.info "Can run only in India production"
    #   return
    # end

    ActiveRecord::Base.transaction do
      delete_patient_data
      delete_app_users
      delete_dashboard_users
      delete_regions
      delete_facilities

      raise ActiveRecord::Rollback if dry_run
    end
  end

  def self.call(*args)
    new(*args).call
  end

  def initialize(organization_id:, facilities:, dry_run: true)
    @organization_id = organization_id
    @facilities = facilities
    @dry_run = dry_run
  end

  def call
    ActiveRecord::Base.transaction do
      delete_patient_data
      delete_app_users
      delete_dashboard_users
      delete_regions
      delete_facilities
      delete_facility_groups
      delete_organization

      raise ActiveRecord::Rollback if dry_run
    end
  end

  private

  attr_reader :organization_id, :dry_run

  def delete_patient_data
    patients = Patient.with_discarded.where(registration_facility_id: facilities)
    addresses = Address.with_discarded.where(id: patients.pluck(:address_id))

    appointments = Appointment.with_discarded.where(facility_id: facilities)
    bps = BloodPressure.with_discarded.where(patient_id: patients)
    blood_sugars = BloodSugar.with_discarded.where(patient_id: patients)
    medical_histories = MedicalHistory.with_discarded.where(patient_id: patients)
    prescription_drugs = PrescriptionDrug.with_discarded.where(patient_id: patients)

    patient_phone_numbers = PatientPhoneNumber.with_discarded.where(patient_id: patients)
    exotel_phone_number_details = ExotelPhoneNumberDetail.with_discarded.where(patient_phone_number_id: patient_phone_numbers)

    patient_business_identifiers = PatientBusinessIdentifier.with_discarded.where(patient_id: patients)
    passport_authentications = PassportAuthentication.where(patient_business_identifier: patient_business_identifiers)

    encounters = Encounter.with_discarded.where(facility_id: facilities)
    observations = Observation.with_discarded.where(encounter_id: encounters)

    records = [appointments,
      bps,
      blood_sugars,
      medical_histories,
      prescription_drugs,
      exotel_phone_number_details,
      patient_phone_numbers,
      passport_authentications,
      patient_business_identifiers,
      observations,
      encounters,
      patients,
      addresses]

    records.map do |record|
      log "#{record.count} #{record.klass.name} deleted"
      record.delete_all
    end
  end

  def delete_app_users
    phone_number_auths = PhoneNumberAuthentication.with_discarded.where(registration_facility_id: facilities)
    user_auths =
      UserAuthentication
        .with_discarded
        .where(authenticatable_type: "PhoneNumberAuthentication")
        .where(authenticatable_id: phone_number_auths)
    user_ids = user_auths.pluck(:user_id)
    users = User.with_discarded.where(id: user_ids)

    log "#{user_auths.count} UserAuthentication deleted"
    log "#{phone_number_auths.count} PhoneNumberAuthentication deleted"
    log "#{users.count} App users deleted"

    user_auths.delete_all
    phone_number_auths.delete_all
    users.delete_all
  end

  def delete_dashboard_users
    users =
      User
        .with_discarded
        .where(organization_id: organization_id)
        .joins("LEFT OUTER JOIN user_authentications ON users.id = user_authentications.user_id")
        .where(user_authentications: {authenticatable_type: "EmailAuthentication"})
        .where("user_authentications.id IS NOT NULL")
    email_auths = EmailAuthentication.joins(:user_authentication).with_discarded.where(user_authentications: {user_id: users})
    user_auths = UserAuthentication.with_discarded.where(user_id: users)
    accesses = Access.where(user_id: users)

    log "#{accesses.count} Access deleted"
    log "#{user_auths.count} UserAuthentication deleted"
    log "#{email_auths.count} EmailAuthentication deleted"
    log "#{users.count} Dashboard users deleted"

    accesses.delete_all
    user_auths.delete_all
    email_auths.delete_all
    users.delete_all
  end

  def delete_regions
    regions = Region.find_by(source_id: @organization_id)&.self_and_descendants
    if regions.present?
      log "#{regions.count} Region deleted"
      regions.delete_all
    end
  end

  def delete_facilities
    log "#{facilities.count} Facility deleted"
    facilities.destroy_all
  end

  def delete_facility_groups
    log "#{facility_groups.count} FacilityGroup deleted"
    facility_groups.destroy_all
  end

  def delete_organization
    organization = organization.find(@organization_id)
    log "#{organization.name} Organization deleted"
    organization.destroy
  end

  memoize def facility_groups
    FacilityGroup.with_discarded.where(organization_id: @organization_id)
  end

  memoize def facilities
    @facilities || Facility.with_discarded.where(facility_group_id: @facility_groups)
  end

  def log(*args)
    puts(*args)
    Rails.logger.info(*args)
  end
end
