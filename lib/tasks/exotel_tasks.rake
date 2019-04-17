namespace :exotel_tasks do
  desc 'Whitelist patient phone numbers on Exotel'
  task whitelist_patient_phone_numbers: :environment do
    require 'exotel_tasks/whitelist_phone_numbers'

    data_file = ENV.fetch('JSON_FILE_PATH')
    account_sid = ENV.fetch('ACCOUNT_SID')
    token = ENV.fetch('TOKEN')
    virtual_number = ENV.fetch('VIRTUAL_NUMBER')
    batch_size = (ENV['BATCH_SIZE'] || 1000).to_i

    if data_file.blank? || account_sid.blank? || token.blank?
      puts 'Please specify all of: JSON_FILE_PATH, ACCOUNT_SID and TOKEN as env vars to continue'
      abort 'Exiting...'
    end

    task = ExotelTasks::WhitelistPhoneNumbers.new(account_sid, token, data_file)

    trap("SIGINT") do
      pp task.stats
      abort 'Exiting...'
    end

    logger.tagged('Whitelisting patient phone numbers') do
      task.process(batch_size, virtual_number)
      pp task.stats
      logger.debug("#{task.stats}")
    end
  end
end
