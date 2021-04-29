class PatientImport::ImportUser
  IMPORT_USER_PHONE_NUMBER = "0000000001"

  def self.find_or_create
    find || create
  end

  def self.find
    PhoneNumberAuthentication.find_by(phone_number: IMPORT_USER_PHONE_NUMBER)&.user
  end

  def self.create
    user = User.new(
      full_name: "import-user",
      organization_id: Organization.take,
      device_created_at: Time.current,
      device_updated_at: Time.current
    )

    phone_number_authentication = PhoneNumberAuthentication.new(
      phone_number: IMPORT_USER_PHONE_NUMBER,
      password: "#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}",
      registration_facility_id: Facility.take.id
    ).tap do |pna|
      pna.set_otp
      pna.invalidate_otp
      pna.set_access_token
    end

    user.phone_number_authentications = [phone_number_authentication]
    user.sync_approval_denied("bot user for import")
    user.save!

    user
  end
end
