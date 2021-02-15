class RegionCacheWarmerJob
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(region_id, period_attributes)
    region = Region.find(region_id)
    period = Period.new(period_attributes)

    Reports::RegionService.call(region: region, period: period)
    Statsd.instance.increment("region_cache_warmer.#{region.region_type}.cache")

    Reports::RegionService.call(region: region, period: period, with_exclusions: true)
    Statsd.instance.increment("region_cache_warmer.with_exclusions.#{region.region_type}.cache")
  end
end
