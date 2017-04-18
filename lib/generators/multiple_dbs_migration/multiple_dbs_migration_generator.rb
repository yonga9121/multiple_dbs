require 'rails/generators/active_record/migration/migration_generator'

class MultipleDbsMigrationGenerator < ActiveRecord::Generators::MigrationGenerator
  source_root File.join(File.dirname(ActiveRecord::Generators::MigrationGenerator.instance_method(:create_migration_file).source_location.first), "templates")

  class_option :only, type: :array, default: []
  class_option :skip, type: :array, default: []

  def create_migration_file
    if MultipleDbs and MultipleDbs::DBS
      set_local_assigns!
      validate_file_name!
      only_arr = options[:only].map{|o| o.to_sym }.delete_if{ |o| !MultipleDbs::DBS.include?(o)} if options[:only] and options[:only].any?
      skip_arr = options[:skip].map{|s| s.to_sym }.delete_if{ |s| !MultipleDbs::DBS.include?(s)} if options[:skip] and options[:skip].any?
      databases_list = (MultipleDbs::DBS & only_arr) if only_arr and only_arr.any?
      databases_list = databases_list - skip_arr if skip_arr and skip_arr.any?
      databases_list ||= MultipleDbs::DBS
      databases_list.each do |branch|
        migration_template @migration_template, "db/#{branch}/migrate/#{file_name}.rb"
      end if databases_list.any?
    else
      puts "The multiple_dbs constant is not defined. The multiple_dbs generator must be runned first. Type in your console: rails g multiple_dbs --help"
    end
  end
end
