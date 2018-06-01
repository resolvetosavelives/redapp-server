class Api::V1::PayloadValidator
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks
  include ActiveModel::Validations

  after_validation :capture_error

  def initialize(attributes = {})
    @attributes = attributes.to_hash.with_indifferent_access
    super(attributes)
  end

  def schema_with_definitions
    schema.merge(definitions: Api::V1::Spec.all_definitions)
  end

  def errors_hash
    errors.to_hash.merge(id: id)
  end

  def validate_schema
    JSON::Validator.fully_validate(schema_with_definitions, to_json).each do |error_string|
      errors.add(:schema, error_string)
    end
  end

  private

  def capture_error
    return unless errors.present?

    Raven.capture_message(
      'Validation Error',
      logger: 'logger',
      extra: {
        schema_errors: errors[:schema],
        non_schema_errors: errors.to_hash.except(:schema),
        attributes: @attributes
      },
      tags: { validation: 'schema' }
    )
  end
end