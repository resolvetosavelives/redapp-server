class Region < ApplicationRecord
  MAX_LABEL_LENGTH = 255

  ltree :path
  extend FriendlyId
  friendly_id :name, use: :slugged

  validates :name, presence: true
  validates :slug, presence: true
  validates :path, presence: true, uniqueness: true

  belongs_to :type, class_name: "RegionType", foreign_key: "region_type_id"
  belongs_to :source, polymorphic: true, optional: true

  before_validation :set_path, if: :parent
  before_discard :remove_path

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

  def set_path
    self.path = "#{parent.path}.#{name_to_path_label}"
  end

  def remove_path
    self.path = nil
  end

  def parent=(parent)
    @parent = parent
  end

  def parent
    @parent || super
  end
end
