module RegionSource
  def self.extended(klass)
    klass.has_one :region, inverse_of: :source, foreign_key: "source_id"
    klass.after_discard do
      region.discard
    end
  end
end
