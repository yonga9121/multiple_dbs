
# Regexp used to find the databases list.
REGEX_MATCH_FILES_BY_NAME = /config\/multiple_dbs\/([a-zA-Z]+[0-9]*|[0-9]+[a-zA-Z]*)_database.yml/

# @dbs Store all the databases names
@dbs = []

# Search in the config/multiple_dbs directory and scan each filename looking for each database name
Dir["config/multiple_dbs/*"].each do |file|
  @dbs << file.scan(REGEX_MATCH_FILES_BY_NAME)
end
@dbs.flatten!


# MultipleDbs namespace
namespace :mdbs do
  # Looping all the databases
  @dbs.each do |db|
    desc "databases managment #{db} tasks"
    # A namespace per database
    namespace db.to_sym do |database|
      desc "#{db} drop"
      task :drop do
        Rake::Task["db:drop"].invoke
      end
      desc "#{db} create"
      task :create do
        Rake::Task["db:create"].invoke
      end
      desc "#{db} setup"
      task :setup do
        Rake::Task["db:setup"].invoke
      end
      desc "#{db} migrate"
      task :migrate do
        Rake::Task["db:migrate"].invoke
      end
      desc "#{db} rollback"
      task :rollback do
        Rake::Task["db:rollback"].invoke
      end
      desc "#{db} seed"
      task :seed  do
        Rake::Task["db:seed"].invoke
      end
      desc "#{db} version"
      task :version do
        Rake::Task["db:version"].invoke
      end

      namespace :schema do
        desc "#{db} schema load"
        task :load do
          Rake::Task["db:schema:load"].invoke
        end
        desc "#{db} schema dump"
        task :dump do
          Rake::Task["db:schema:dump"].invoke
        end
      end

      database.tasks.each do |task|
        task.enhance ["mdbs:#{db}:set_custom_config"] do
          Rake::Task["mdbs:#{db}:revert_to_original_config"].invoke
        end
      end

      desc "#{db} set custom config"
      task "set_custom_config".to_sym do
        # save current vars
        @original_config = {
          env_schema: ENV['SCHEMA'],
          config: Rails.application.config.dup
        }
        # set config variables for custom database
        ENV['SCHEMA'] = "db/#{db}/schema.rb"
        Rails.application.config.paths['db'] = ["db/#{db}"]
        Rails.application.config.paths['db/migrate'] = ["db/#{db}/migrate"]
        Rails.application.config.paths['db/seeds.rb'] = ["db/#{db}/seeds.rb"]
        Rails.application.config.paths['config/database'] = ["config/multiple_dbs/#{db}_database.yml"]
      end
      desc "#{db} revert custom config"
      task "revert_to_original_config".to_sym do
        # reset config variables to original values
        ENV['SCHEMA'] = @original_config[:env_schema]
        Rails.application.config = @original_config[:config]
      end
    end #db tasks

  end # looping dbes

  desc "drop all dbs and delete their schema file"
  task :hard_drop do
    @dbs.each do |db|
      puts "hard dropping #{db}"
      puts system(" rake mdbs:#{db}:drop") ? "#{db} dropped" :  "Error while dropping #{db}"
      puts system(" rm -rf db/#{db}/schema.rb ") ? "schema from #{db} removed" : "Error while erasing the schema from #{db}"
    end
  end

  desc "drop, delete the schema files, create, migrate and seed for all dbs"
  task :hard_reset do
    @dbs.each do |db|
      puts "hard reset #{db}"
      puts system(" rake mdbs:#{db}:drop") ? "#{db} dropped" : "Error while dropping #{db}"
      puts system(" rm -rf db/#{db}/schema.rb ") ? "schema from #{db} removed" : "Error while erasing the schema from #{db}"
      puts system(" rake mdbs:#{db}:create") ? "#{db} created" : "Error while creating #{db}"
      puts system(" rake mdbs:#{db}:migrate") ? "#{db} migrated" : "Error while migrating #{db}"
      puts system(" rake mdbs:#{db}:seed") ? "#{db} seeded" : "Error while seeding #{db}"
    end
  end

  desc "copy the seeds from the db/seed.rb file to each dbs seed file."
  task :copy_seeds do
    @dbs.each do |db|
      puts "Copy seed to #{db}. #{system('cp db/seeds.rb db/#{db}/seeds.rb')}"
    end
  end

  desc "copy the specified migration to each dbs migrations folder. Parameters: full_path.rb, database_name"
  task :copy_migration, [:file_name, :db_name] do |t, args|
    @dbs.each do |db|
      puts "Copy migration from db/#{args[:db_name].downcase}/migrate/#{args[:file_name]} to db/#{db}/migrate/#{args[:file_name]}."
      puts system("cp db/#{args[:db_name].downcase}/migrate/#{args[:file_name]} db/#{db}/migrate/#{args[:file_name]} ")
    end
  end

  desc "copy the specified migration to the specified db migrations folder. Parameters: full_path.rb, from_database_name, to_database_name"
  task :copy_migration_into, [:file_name, :from_database_name, :to_database_name] do |t, args|
      puts "Copy migration from db/#{args[:from_database_name].downcase}/migrate/#{args[:file_name]} to db/#{args[:to_database_name]}/migrate/#{args[:file_name]}."
      puts system("cp db/#{args[:from_database_name].downcase}/migrate/#{args[:file_name]} db/#{args[:to_database_name]}/migrate/#{args[:file_name]} ")
  end

  desc "copy the specified migration from the default migrations folder db/migrate to each dbs migrations folder. Parameters: full_path.rb"
  task :copy_migration_from_default, [:file_name] do |t, args|
    @dbs.each do |db|
      puts "Copy migration from db/migrate/#{args[:file_name]} to db/#{db}/migrate/#{args[:file_name]}."
      system(" mkdir db/#{db}")
      system(" mkdir db/#{db}/migrate")
      puts system("cp db/migrate/#{args[:file_name]} db/#{db}/migrate/#{args[:file_name]} ")
    end
  end

  desc "copy the db/migration folder into each of your databases"
  task :replicate_default_database do
    @dbs.each do |db|
      puts "Copy folder db/migrate to db/#{db}"
      system(" mkdir db/#{db}")
      puts system("cp -r db/migrate db/#{db}")
    end
  end

  desc "copy the db/migration folder into the specified database"
  task :replicate_default_database_into,[:db_name] do |t, args|
      puts "Copy folder db/migrate to db/#{args[:db_name]}/migrate"
      system(" mkdir db/#{args[:db_name]}")
      puts system("cp -r db/migrate db/#{args[:db_name]}/migrate")
  end

  desc "copy the specified migration from the default migrations folder db/migrate, to the specified db migrations folder. Parameters: full_path.rb, to_database_name"
  task :copy_migration_from_default_into, [:file_name, :to_database_name] do |t, args|
      puts "Copy migration from db/migrate/#{args[:file_name]} to db/#{args[:to_database_name]}/migrate/#{args[:file_name]}."
      system(" mkdir db/#{args[:to_database_name]}")
      system(" mkdir db/#{args[:to_database_name]}/migrate")
      puts system("cp db/migrate/#{args[:file_name]} db/#{args[:to_database_name]}/migrate/#{args[:file_name]} ")
  end

  desc "drop all dbs"
  task :drop do
      puts "Droping #{@dbs.join(',')}."
      @dbs.each do |db|
        Rake::Task["mdbs:#{db}:drop"].invoke
        Rake::Task["db:drop"].reenable
        Rake::Task["db:load_config"].reenable
        Rake::Task["db:drop:_unsafe"].reenable
        puts "#{db} dropped"
      end
  end
  desc "create all dbs"
  task :create do
      @dbs.each do |db|
        puts system(" rake mdbs:#{db}:create") ? "#{db} created" : "Error while creating #{db}"
      end
  end
  desc "setup all dbs"
  task :setup do
      @dbs.each do |db|
        puts system(" rake mdbs:#{db}:setup") ? "#{db} setup completed" : "Error while setting up #{db}"
      end
  end
  desc "migrate all dbs"
  task :migrate do
      @dbs.each do |db|
        puts system( "rake mdbs:#{db}:migrate" ) ? "#{db} migrated" : "Error while migrating #{db}"
      end
  end
  desc "rollback all dbs"
  task :rollback do
      @dbs.each do |db|
        puts system( "rake mdbs:#{db}:migrate" ) ? "#{db} rollback completed" : "Error while executing rollback on #{db}"
      end
  end
  desc "seed all dbs"
  task :seed do
      @dbs.each do |db|
        puts system( "rake mdbs:#{db}:seed" ) ? "#{db} seeded" : "Error while seeding #{db}"
      end
  end
  desc "version all dbs"
  task :version do
      puts "Please use specific task for each database. Ex mdbs:my_db:version"
  end
  namespace :schema do
    desc "schema load all dbs"
    task :load do
        @dbs.each do |db|
          puts system(" rake mdbs:#{db}:schema:load ") ? "#{db} schema loaded" : "Error while loading schema for #{db}"
        end
    end
    desc "schema dump all dbs"
    task :dump do
        @dbs.each do |db|
          puts system(" rake mdbs:#{db}:schema:dump ") ? "#{db} schema dumped" : "Error while dumping schema for #{db}"
        end
    end
  end
end
