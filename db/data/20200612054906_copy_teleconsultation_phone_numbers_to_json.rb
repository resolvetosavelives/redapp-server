class CopyTeleconsultationPhoneNumbersToJson < ActiveRecord::Migration[5.2]
  def up
    Facility.all.each do |facility|
      next if facility.teleconsultation_phone_number.blank? || facility.teleconsultation_isd_code.blank?

      facility.teleconsultation_phone_numbers = [{isd_code: facility.teleconsultation_isd_code,
                                                  phone_number: facility.teleconsultation_phone_number}]
      facility.save
    end
  end

  def down
    Facility.all.each do |facility|
      facility.teleconsultation_phone_numbers = []
      facility.save
    end
  end
end
