json.v1 @countries.each do |country|
  country_config = CountryConfig.for(country)

  json.country_code country_config[:abbreviation]
  json.endpoint "#{ENV["SIMPLE_SERVER_HOST_PROTOCOL"]}://#{ENV["SIMPLE_SERVER_HOST"]}/api/"
  json.display_name country_config[:name]
  json.isd_code country_config[:sms_country_code].tr("+", "")
end
