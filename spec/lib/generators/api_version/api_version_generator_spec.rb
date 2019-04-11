require 'rails_helper'
require 'generator_spec'

require 'generators/api_version/api_version_generator'

RSpec.describe ApiVersionGenerator, type: :generator do
  CURRENT_VERSION = 'v2'
  NEW_VERSION = 'v3'

  let(:spec_root) { Rails.root.join('spec') }

  destination(Rails.root.join('spec', 'tmp'))
  arguments ['--current-version', CURRENT_VERSION, '--new-version', NEW_VERSION]

  before(:all) do
    prepare_destination
    run_generator
  end

  after(:all) do
    prepare_destination
  end

  def files_in_directory(directory)
    Dir[directory.join('**', '*.rb')]
      .map { |file| file.to_s.remove(Rails.root.to_s) }
  end

  describe 'generates the scaffold required to migrate to a new API version' do
    describe 'copy current specs for the give current version' do
      it 'api specs' do
        current_spec_files = files_in_directory(spec_root.join('api', 'current'))


        current_spec_files.each do |path|
          new_file_path = path.sub('current', CURRENT_VERSION)
          assert_file(destination_root.to_s + new_file_path, Regexp.new("#{CURRENT_VERSION}/swagger.json"))
          assert_file(destination_root.to_s + new_file_path, Regexp.new(CURRENT_VERSION.capitalize))
        end
      end


      it 'controller specs' do
        current_spec_files = files_in_directory(spec_root.join('controllers', 'api', 'current'))

        current_spec_files.each do |path|
          new_file_path = path.sub('current', CURRENT_VERSION)
          assert_file(destination_root.to_s + new_file_path, Regexp.new("Api::#{CURRENT_VERSION.capitalize}"))
        end
      end

      it 'payload specs ' do
        current_spec_files = files_in_directory(spec_root.join('payloads', 'api', 'current'))

        current_spec_files.each do |path|
          new_file_path = path.sub('current', CURRENT_VERSION)
          assert_file(destination_root.to_s + new_file_path, Regexp.new("Api::#{CURRENT_VERSION.capitalize}"))
        end
      end

      it 'request specs' do
        current_spec_files = files_in_directory(spec_root.join('requests', 'api', 'current'))

        current_spec_files.each do |path|
          new_file_path = path.sub('current', CURRENT_VERSION)
          assert_file(destination_root.to_s + new_file_path, Regexp.new("Api::#{CURRENT_VERSION.capitalize}"))
        end
      end
    end

    describe 'creates controllers for the given current version' do
      it 'creates controller files' do
        assert_directory("#{destination_root}/app/controllers/api/#{CURRENT_VERSION}")
      end

      it 'creates template controllers for the given current version' do
        controllers_root = Rails.root.join('app', 'controllers')
        expected_relative_paths = Dir[controllers_root.join('api', 'current', '**', '*.rb')]
                                  .map { |path| path.remove(controllers_root.to_s).sub('current', CURRENT_VERSION) }

        expected_controllers = expected_relative_paths.map do |relative_path|
          [relative_path, relative_path.sub('.rb', '').split('/').reject(&:empty?).map { |name| name.camelcase }.join('::')]
        end.to_h

        expected_controllers.each do |file, controller_name|
          inheriting_controller_name = controller_name.sub(CURRENT_VERSION.capitalize, 'Current')
          expected_file_path = destination_root.to_s + '/app/controllers' + file
          assert_file(expected_file_path, Regexp.new("^class #{controller_name} < #{inheriting_controller_name}\nend"))
        end
      end
    end

    describe 'creates transformers for the given current version' do
      it 'creates transformers directory for the new version' do
        assert_directory("#{destination_root}/app/transformers/api/#{CURRENT_VERSION}")
      end

      it 'creates template transformers for the given current version' do
        transformers_root = Rails.root.join('app', 'transformers')
        expected_relative_paths = Dir[transformers_root.join('api', 'current', '**', '*.rb')]
                                    .map { |path| path.remove(transformers_root.to_s).sub('current', CURRENT_VERSION) }

        expected_transformers = expected_relative_paths.map do |relative_path|
          [relative_path, relative_path.sub('.rb', '').split('/').reject(&:empty?).map { |name| name.camelcase }.join('::')]
        end.to_h

        expected_transformers.each do |file, transformer_name|
          inheriting_transformer_name = transformer_name.sub(CURRENT_VERSION.capitalize, 'Current')
          expected_file_path = destination_root.to_s + '/app/transformers' + file
          assert_file(expected_file_path, Regexp.new("^class #{transformer_name} < #{inheriting_transformer_name}\nend"))
        end
      end
    end

    describe 'creates validators for the given current version' do
      it 'creates validators directory for the new version' do
        assert_directory("#{destination_root}/app/validators/api/#{CURRENT_VERSION}")
      end

      it 'creates template validators for the given current version' do
        validators_root = Rails.root.join('app', 'validators')
        expected_relative_paths = Dir[validators_root.join('api', 'current', '**', '*.rb')]
                                    .map { |path| path.remove(validators_root.to_s).sub('current', CURRENT_VERSION) }

        expected_validators = expected_relative_paths.map do |relative_path|
          [relative_path, relative_path.sub('.rb', '').split('/').reject(&:empty?).map { |name| name.camelcase }.join('::')]
        end.to_h

        expected_validators.each do |file, validator_name|
          inheriting_validator_name = validator_name.sub(CURRENT_VERSION.capitalize, 'Current')
          expected_file_path = destination_root.to_s + '/app/validators' + file
          assert_file(expected_file_path, Regexp.new("^class #{validator_name} < #{inheriting_validator_name}\nend"))
        end
      end
    end

    describe 'creates schema for the given current version' do
      it 'copies the schema files' do
        expect(destination_root.to_s + '/app/schema/api').to have_structure {
          directory CURRENT_VERSION do
            file 'models.rb'
            file 'schema.rb'
          end
        }
      end
    end
  end
end