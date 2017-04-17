class MultipleDbsInitializerGenerator < Rails::Generators::Base
  source_root File.expand_path("../templates", __FILE__)

  ## @@default_db_config
  #  default database configuration
  @@default_db_config = {
    "adapter"=> "postgresql",
    "encoding"=> "unicode",
    "pool"=> 5,
    "username"=> "root",
    "password"=> "toor",
  }

  ## databases = [:db1, :db2]
  # an array that stores the databases names.
  argument :databases, type: :array, default: [:db1, :db2]

  ## development = @@default_db_config
  #  a hash that allows the user to change the default database configuration
  #  for the development environment through the options
  class_option :development, type: :hash, default: @@default_db_config
  ## production = @@default_db_config
  #  a hash that allows the user to change the default database configuration
  #  for the production environment through the options
  class_option :production, type: :hash, default: @@default_db_config
  ## test = @@default_db_config
  #  a hash that allows the user to change the default database configuration
  #  for the test environment through the options
  class_option :test, type: :hash, default: @@default_db_config


  ## define_multiple_dbs_constant
  #  Create the multiple_dbs_initializer.rb file.
  #  This file define the MultipleDbs::DBS constant
  #  and the MultipleDbs::DbConnection per database.
  #  Also delete the config/multiple_dbs folder and
  #  create the ymls files that store the database
  #  configuration
  def define_multiple_dbs_constant
    copy_file "initializer.rb", "config/initializers/multiple_dbs_initializer.rb"
    insert_into_file "config/initializers/multiple_dbs_initializer.rb",
    %Q{\tDBS=#{databases.map{|db| db.to_s.underscore.to_sym}}\n}, after: "# Your databases.\n", verbose: false
    insert_into_file "config/initializers/multiple_dbs_initializer.rb",
    %Q{\t\tDBS.each do |db|
      const_set(db.to_s.capitalize , Class.new do
        attr_accessor :connection
        @connection = YAML::load(ERB.new(File.read(Rails.root.join("config/multiple_dbs", db.to_s.downcase  + "_database.yml"))).result)[Rails.env]
        def self.connection
          @connection
        end
      end)
    end\n},
    after: "# DbConnection Constants.\n", verbose: false
    remove_file "config/multiple_dbs"
    databases.each do |db|
      create_database_config_file db
    end
    create_database_config_file
  end

  private


  ## create_database_config_file
  #  create the configuration yml file for the given database name
  #  if the database name is null then the default rails configuration file is
  #  Overwritten
  def create_database_config_file(db = nil)
    fpath = db ? "/multiple_dbs/#{db}_database.yml" : "/database.yml"
    db ||= MultipleDbs::DBS.first
    copy_file "config_db.yml", "config#{fpath}"

    insert_into_file "config#{fpath}",
    %Q{#{options.development["adapter"] ? options.development["adapter"] : @@default_db_config["adapter"] } },
    before: "#development_adapter", verbose: false, force: true
    insert_into_file "config#{fpath}",
    %Q{#{options.development["encoding"] ? options.development["encoding"] : @@default_db_config["encoding"] } },
    before: "#development_encoding", verbose: false, force: true
    insert_into_file "config#{fpath}",
    %Q{#{options.development["pool"] ? options.development["pool"] : @@default_db_config["pool"] } },
    before: "#development_pool", verbose: false, force: true
    insert_into_file "config#{fpath}",
    %Q{#{db}_development },
    before: "#development_database", verbose: false, force: true
    insert_into_file "config#{fpath}",
    %Q{#{options.development["username"] ? options.development["username"] : @@default_db_config["username"] } },
    before: "#development_username", verbose: false, force: true
    insert_into_file "config#{fpath}",
    %Q{#{options.development["password"] ? options.development["password"] : @@default_db_config["password"] } },
    before: "#development_psw", verbose: false, force: true

    insert_into_file "config#{fpath}",
    %Q{#{options.production["adapter"] ? options.production["adapter"] : @@default_db_config["adapter"] } },
    before: "#production_adapter", verbose: false, force: true
    insert_into_file "config#{fpath}",
    %Q{#{options.production["encoding"] ? options.production["encoding"] : @@default_db_config["encoding"] } },
    before: "#production_encoding", verbose: false, force: true
    insert_into_file "config#{fpath}",
    %Q{#{options.production["pool"] ? options.production["pool"] : @@default_db_config["pool"] } },
    before: "#production_pool", verbose: false, force: true
    insert_into_file "config#{fpath}",
    %Q{#{db}_production },
    before: "#production_database", verbose: false, force: true
    insert_into_file "config#{fpath}",
    %Q{#{options.production["username"] ? options.production["username"] : @@default_db_config["username"] } },
    before: "#production_username", verbose: false, force: true
    insert_into_file "config#{fpath}",
    %Q{#{options.production["password"] ? options.production["password"] : @@default_db_config["password"] } },
    before: "#production_psw", verbose: false, force: true

    insert_into_file "config#{fpath}",
    %Q{#{options.test["adapter"] ? options.test["adapter"] : @@default_db_config["adapter"] } },
    before: "#test_adapter", verbose: false, force: true
    insert_into_file "config#{fpath}",
    %Q{#{options.test["encoding"] ? options.test["encoding"] : @@default_db_config["encoding"] } },
    before: "#test_encoding", verbose: false, force: true
    insert_into_file "config#{fpath}",
    %Q{#{options.test["pool"] ? options.test["pool"] : @@default_db_config["pool"] } },
    before: "#test_pool", verbose: false, force: true
    insert_into_file "config#{fpath}",
    %Q{#{db}_test },
    before: "#test_database", verbose: false, force: true
    insert_into_file "config#{fpath}",
    %Q{#{options.test["username"] ? options.test["username"] : @@default_db_config["username"] } },
    before: "#test_username", verbose: false, force: true
    insert_into_file "config#{fpath}",
    %Q{#{options.test["password"] ? options.test["password"] : @@default_db_config["password"] } },
    before: "#test_psw", verbose: false, force: true
  end

end
