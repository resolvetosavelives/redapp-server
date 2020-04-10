class SetLocalTimezone
  def call(_worker, _job, _queue)
    begin
      Time.use_zone(Rails.application.config.country[:time_zone] || 'UTC') do
        yield
      end
    rescue => ex
      puts ex.message
    end
  end
end

module SidekiqConfig
  DEFAULT_REDIS_POOL_SIZE = 12

  Sidekiq::Extensions.enable_delay!

  def self.connection_pool
    ConnectionPool.new(size: Config.get_int('SIDEKIQ_REDIS_POOL_SIZE', DEFAULT_REDIS_POOL_SIZE)) do
      if ENV['SIDEKIQ_REDIS_HOST'].present?
        Redis.new(host: ENV['SIDEKIQ_REDIS_HOST'])
      else
        Redis.new
      end
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = SidekiqConfig.connection_pool
end

Sidekiq.configure_server do |config|
  config.server_middleware { |chain| chain.add SetLocalTimezone }
  config.redis = SidekiqConfig.connection_pool
end

require "sidekiq/throttled"
Sidekiq::Throttled.setup!
