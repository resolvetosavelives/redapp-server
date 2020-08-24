class RegionReportCacheWarmer
  def self.call
    new.call
  end

  def initialize(period: Date.current.last_month.beginning_of_month)
    @period = period
  end

  delegate :logger, to: Rails

  def call
    FacilityGroup.all.each do |region|
      logger.info { "class=#{self.class.name} region=#{region.name}" }
      RegionReportService.new(region: region, period: @period).call
    end
    Facility.all.each do |region|
      logger.info { "class=#{self.class.name} region=#{region.name}" }
      RegionReportService.new(region: region, period: @period).call
    end
  end
end