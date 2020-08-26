class AddTeleconsultationPhoneNumberToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :teleconsultation_phone_number, :string
    add_column :users, :teleconsultation_isd_code, :string
  end
end
