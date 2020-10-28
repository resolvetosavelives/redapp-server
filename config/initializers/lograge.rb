Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.custom_options = lambda do |event|
    exceptions = %w[controller action format id]
    {
      cache_stats: RequestStore[:cache_stats],
      params: event.payload[:params].except(*exceptions)
    }
  end
  config.lograge.formatter = Class.new do |fmt|
    def fmt.call(data)
      {msg: "request"}.merge(data)
    end
  end
end
