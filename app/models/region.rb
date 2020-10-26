class Region < ApplicationRecord
  ltree :path
  extend FriendlyId
  friendly_id :name, use: :slugged

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :path, presence: true

  belongs_to :type, class_name: "RegionType", foreign_key: "region_type_id"
  belongs_to :source, polymorphic: true, optional: true

  before_discard do
    self.path = nil
  end

  MAX_LABEL_LENGTH = 255

  # A label is a sequence of alphanumeric characters and underscores.
  # (In C locale the characters A-Za-z0-9_ are allowed).
  # Labels must be less than 256 bytes long.
  def name_to_path_label
    name.gsub(/\W/, "_").slice(0, MAX_LABEL_LENGTH)
  end

  def log_payload
    attrs = attributes.slice("name", "slug", "path")
    attrs["id"] = id.presence
    attrs["region_type"] = type.name
    attrs["valid"] = valid?
    attrs["errors"] = errors.full_messages.join(",") if errors.any?
    attrs.symbolize_keys
  end

  RegionType.all.map do |region_type|
    define_method(region_type.name.underscore) do
      if region_type.self_and_descendants.include?(type)
        self_and_ancestors.find_by(region_type_id: region_type)
      else
        raise NoMethodError, "undefined method #{region_type.name.underscore} for #{self} of type #{type.name}"
      end
    end

    define_method(region_type.name.pluralize.underscore) do
      if region_type.ancestors.include?(type)
        descendants.where(type: region_type)
      else
        raise NoMethodError, "undefined method #{region_type.name.pluralize.underscore} for #{self} of type #{type.name}"
      end
    end
  end
end
