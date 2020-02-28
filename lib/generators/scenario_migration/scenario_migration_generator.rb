# frozen_string_literal: true

require 'rails/generators/active_record/migration/migration_generator'

class ScenarioMigrationGenerator < ActiveRecord::Generators::MigrationGenerator
  source_root File.expand_path('templates', __dir__)

  def create_migration_file
    set_local_assigns!
    validate_file_name!

    migration_template @migration_template, "db/migrate/#{file_name}.rb"
  end
end
