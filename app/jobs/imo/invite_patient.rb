class Imo::InvitePatient
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(patient_id)
    return unless Flipper.enabled?(:imo_messaging)

    patient = Patient.find(patient_id)
    ImoApiService.new.invite(patient)
  end
end
