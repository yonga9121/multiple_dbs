require 'rails/generators/active_record/migration/migration_generator'

class MultipleDbsMigrationGenerator < ActiveRecord::Generators::MigrationGenerator
  source_root File.join(File.dirname(ActiveRecord::Generators::MigrationGenerator.instance_method(:create_migration_file).source_location.first), "templates")
  def create_migration_file
    if MultipleDbs and MultipleDbs::DBS
      set_local_assigns!
      validate_file_name!
      MultipleDbs::DBS.each do |branch|
        migration_template @migration_template, "db/#{branch}/migrate/#{file_name}.rb"
      end
    else
      puts "The multiple_dbs constant is not defined. The multiple_dbs generator must be runned first. Type in your console: rails g multiple_dbs --help"
    end
  end
end
