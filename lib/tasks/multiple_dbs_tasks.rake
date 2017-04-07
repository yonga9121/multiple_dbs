
namespace :multiple_dbs_tasks do

  MultipleDbs::DBS.each do |branch|
    desc "databases managment #{branch} tasks"
    namespace branch.to_sym do |database|
      desc "#{branch} drop"
      task :drop do
        Rake::Task["db:drop"].invoke
      end
      desc "#{branch} create"
      task :create do
        Rake::Task["db:create"].invoke
      end
      desc "#{branch} setup"
      task :setup do
        Rake::Task["db:setup"].invoke
      end
      desc "#{branch} migrate"
      task :migrate do
        Rake::Task["db:migrate"].invoke
      end
      desc "#{branch} rollback"
      task :rollback do
        Rake::Task["db:rollback"].invoke
      end
      desc "#{branch} seed"
      task :seed  do
        Rake::Task["db:seed"].invoke
      end
      desc "#{branch} version"
      task :version do
        Rake::Task["db:version"].invoke
      end

      namespace :schema do
        desc "#{branch} schema load"
        task :load do
          Rake::Task["db:schema:load"].invoke
        end
        desc "#{branch} schema dump"
        task :dump do
          Rake::Task["db:schema:dump"].invoke
        end
      end

      database.tasks.each do |task|
        task.enhance ["multiple_dbs_tasks:#{branch}:set_custom_config"] do
          Rake::Task["multiple_dbs_tasks:#{branch}:revert_to_original_config"].invoke
        end
      end

      desc "#{branch} set custom config"
      task "set_custom_config".to_sym do
        # save current vars
        @original_config = {
          env_schema: ENV['SCHEMA'],
          config: Rails.application.config.dup
        }
        # set config variables for custom database
        ENV['SCHEMA'] = "db/#{branch}/schema.rb"
        Rails.application.config.paths['db'] = ["db/#{branch}"]
        Rails.application.config.paths['db/migrate'] = ["db/#{branch}/migrate"]
        Rails.application.config.paths['db/seeds.rb'] = ["db/#{branch}/seeds.rb"]
        Rails.application.config.paths['config/database'] = ["config/multiple_dbs/#{branch}_database.yml"]
      end
      desc "#{branch} revert custom config"
      task "revert_to_original_config".to_sym do
        # reset config variables to original values
        ENV['SCHEMA'] = @original_config[:env_schema]
        Rails.application.config = @original_config[:config]
      end
    end #branch tasks

  end # looping branches

  desc "drop all dbs and delete their schema file"
  task :hard_drop do
    MultipleDbs::DBS.each do |branch|
      puts "hard dropping #{branch}"
      puts system(" rake multiple_dbs_tasks:#{branch}:drop") ? "#{branch} dropped" :  "Error while dropping #{branch}"
      puts system(" rm -rf db/#{branch}/schema.rb ") ? "schema from #{branch} removed" : "Error while erasing the schema from #{branch}"
    end
  end

  desc "drop, delete the schema files, create, migrate and seed for all dbs"
  task :hard_reset do
    MultipleDbs::DBS.each do |branch|
      puts "hard reset #{branch}"
      puts system(" rake multiple_dbs_tasks:#{branch}:drop") ? "#{branch} dropped" : "Error while dropping #{branch}"
      puts system(" rm -rf db/#{branch}/schema.rb ") ? "schema from #{branch} removed" : "Error while erasing the schema from #{branch}"
      puts system(" rake multiple_dbs_tasks:#{branch}:create") ? "#{branch} created" : "Error while creating #{branch}"
      puts system(" rake multiple_dbs_tasks:#{branch}:migrate") ? "#{branch} migrated" : "Error while migrating #{branch}"
      puts system(" rake multiple_dbs_tasks:#{branch}:seed") ? "#{branch} seeded" : "Error while seeding #{branch}"
    end
  end

  desc "copy the seeds from the db/seed.rb file to each dbs seed file."
  task :copy_seeds do
    MultipleDbs::DBS.each do |branch|
      puts "Copy seed to #{branch}. #{system('cp db/seeds.rb db/#{branch}/seeds.rb')}"
    end
  end

  desc "copy the specified migration to each dbs migrations folder. Parameters: full_path_with_file_name.rb, database_name"
  task :copy_migration, [:file_name, :branch_name] do |t, args|
    MultipleDbs::DBS.each do |branch|
      puts "Copy seed from db/#{args[:branch_name].downcase}/migrate/#{args[:file_name]} to db/#{branch}/migrate/#{args[:file_name]}."
      puts system("cp db/#{args[:branch_name].downcase}/migrate/#{args[:file_name]} db/#{branch}/migrate/#{args[:file_name]} ")
    end
  end

  desc "drop all dbs"
  task :drop do
      puts "Droping #{MultipleDbs::DBS.join(',')}."
      MultipleDbs::DBS.each do |branch|
        puts system("rake multiple_dbs_tasks:#{branch}:drop") ? "#{branch} dropped" : "Error while dropping #{branch}"
      end
  end
  desc "create all dbs"
  task :create do
      MultipleDbs::DBS.each do |branch|
        puts system(" rake multiple_dbs_tasks:#{branch}:create") ? "#{branch} created" : "Error while creating #{branch}"
      end
  end
  desc "setup all dbs"
  task :setup do
      MultipleDbs::DBS.each do |branch|
        puts system(" rake multiple_dbs_tasks:#{branch}:setup") ? "#{branch} setup completed" : "Error while setting up #{branch}"
      end
  end
  desc "migrate all dbs"
  task :migrate do
      MultipleDbs::DBS.each do |branch|
        puts system( "rake multiple_dbs_tasks:#{branch}:migrate" ) ? "#{branch} migrated" : "Error while migrating #{branch}"
      end
  end
  desc "rollback all dbs"
  task :rollback do
      MultipleDbs::DBS.each do |branch|
        puts system( "rake multiple_dbs_tasks:#{branch}:migrate" ) ? "#{branch} rollback completed" : "Error while executing rollback on #{branch}"
      end
  end
  desc "seed all dbs"
  task :seed do
      MultipleDbs::DBS.each do |branch|
        puts system( "rake multiple_dbs_tasks:#{branch}:seed" ) ? "#{branch} seeded" : "Error while seeding #{branch}"
      end
  end
  desc "version all dbs"
  task :version do
      puts "Please use specific task for each database. Ex multiple_dbs_tasks:my_db:version"
  end
  namespace :schema do
    desc "schema load all dbs"
    task :load do
        MultipleDbs::DBS.each do |branch|
          puts system(" rake multiple_dbs_tasks:#{branch}:schema:load ") ? "#{branch} schema loaded" : "Error while loading schema for #{branch}"
        end
    end
    desc "schema dump all dbs"
    task :dump do
        MultipleDbs::DBS.each do |branch|
          puts system(" rake multiple_dbs_tasks:#{branch}:schema:dump ") ? "#{branch} schema dumped" : "Error while dumping schema for #{branch}"
        end
    end
  end
end
