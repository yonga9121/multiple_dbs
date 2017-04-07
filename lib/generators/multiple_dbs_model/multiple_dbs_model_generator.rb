require 'rails/generators/active_record/model/model_generator'

class MultipleDbsModelGenerator < ActiveRecord::Generators::ModelGenerator
  source_root File.join(File.dirname(ActiveRecord::Generators::ModelGenerator.instance_method(:create_migration_file).source_location.first), "templates")
  def create_migration_file
    if MultipleDbs and MultipleDbs::DBS
      return unless options[:migration] && options[:parent].nil?
      attributes.each { |a| a.attr_options.delete(:index) if a.reference? && !a.has_index? } if options[:indexes] == false
      MultipleDbs::DBS.each do |branch|
        migration_template "../../migration/templates/create_table_migration.rb", "db/#{branch}/migrate/#{table_name}.rb"
      end
    else
      puts "The multiple_dbs constant is not defined. The multiple_dbs generator must be runned first. Type in your console: rails g multiple_dbs --help"
    end
  end

end
