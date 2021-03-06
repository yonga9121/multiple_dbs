module MultipleDbs

  def validate_connection(db)
    conn_klass = const_get("Conn#{db.to_s.camelize}")
    if conn_klass
      ActiveRecord::Base.connection_handler.connection_pools.each do |pool|
        Rails.logger.info "CONN FOUND" and return true if pool.spec.name == conn_klass.to_s
      end
      Rails.logger.info " CONN NOT FOUND. CONNECTION TO #{conn_klass}"
      conn_klass.connection and return true
    else
      raise Exception.new("Undefined constant #{conn_klass}")
    end
  end
  module_function :validate_connection

  # This module should be included in your application ApplicationRecord.
  # It define two class methods for your models. With this two
  # methods you can setup and handle all the models from all the
  # databases you defined.
  module MultiConnectable
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods

      # This method lookup for the subclass related to the database that you pass
      # as an argument and the model in wich you are calling the method.
      # It use Object.const_get to lookup for the constant and also call
      # the method multiple_relations so the relations match the classes
      # that must be matched.
      def multiple_class(connectable_type)
        klass = Object.const_get("#{self.name}#{connectable_type.capitalize}")
        klass.muliple_relations
        klass
      end
      alias :mdb :multiple_class

      # This method define one subclass for each database you define. Why?
      # becouse each subclass handle the connection with the specifyed database
      # and becouse of that we does not have to turn off and on the connections
      # between databases. It's simple, if you have a User model and 3 databases
      # defined db1, db2, db3 this method set the constants UserDb1, UserDb2
      # and UserDb3. UserDb1 handle the connection with the database db1 and so on.
      #
      # EXAMPLE:
      # class User < ApplicationRecord
      #   make_connectable_class do |db|
      #     has_many :post, class_name: "Post#{db}"
      #   end
      # end
      #
      def make_connectable_class(options = {},&block)
        only = options[:only]
        only = only.delete_if{ |o| !MultipleDbs::DBS.include?(o) } if only and only.any?
        database_list = (MultipleDbs::DBS & only) if only and only.any?
        database_list ||=  MultipleDbs::DBS
        database_list.each do |db|
          class_eval do
            Object.const_set("#{self.name}#{db.capitalize}", Class.new(self) do
              class_eval do
                # This constant store the name of the database that this subclass
                # is handling
                const_set("CONNECTABLE_TYPE",db.capitalize)

                # This variable will store the connection_pool that is going to
                # handle the connections for the database. Just initializing  the constant
                Thread.current[const_get("CONNECTABLE_TYPE").to_s.underscore + "_connection"] = nil

                # This filter calls the method multiple_relations
                # setting the relations to the database they should be set
                before_validation :muliple_relations
                # This filter calls the method multiple_relations
                # setting the relations to the database they should be set
                after_find :muliple_relations


                # This variable store the block given  by the user...
                # It is thought to have the definition of the model relations
                # and is used my the method multiple_relations to set them adequately
                @connectable_relations = block_given? ? block : nil

                # This method call the block given by the user. If that block contains
                # the definition of the relations parametrized like this:
                #
                # class User < ApplicationRecord
                #   make_connectable_class do |db|
                #     has_many :post, class_name: "Post#{db}"
                #   end
                # end
                #
                # it will set the :post relation to the database handle by this
                # subclass
                def self.muliple_relations
                  @connectable_relations.call( const_get("CONNECTABLE_TYPE") ) if @connectable_relations
                end

                # return the database name of the database that this subclass
                # is related to
                def self.connectable_type
                  const_get("CONNECTABLE_TYPE")
                end


                # Override the connection method. Search the connection_pool that
                # is handle the database connection, assign it to the
                # Thread.current[const_get("CONNECTABLE_TYPE").to_s.underscore + "_connection"]
                # vairable
                def self.connection
                  self.connection_handler.connection_pools.each do |pool|
                    if pool.spec.config[:database] == eval('DBConnection' + const_get("CONNECTABLE_TYPE").to_s).connection["database"]
                      return Thread.current[const_get("CONNECTABLE_TYPE").to_s.underscore + "_connection"] = pool.connection
                    end
                  end
                end

                private

                # return the database name of the database that this subclass
                # is related to
                def connectable_type
                  const_get("CONNECTABLE_TYPE")
                end

                # Call the class method multiple_relations.
                # This method call the block given by the user. If that block contains
                # the definition of the relations parametrized like this:
                #
                # class User < ApplicationRecord
                #   make_connectable_class do |db|
                #     has_many :post, class_name: "Post#{db}"
                #   end
                # end
                #
                # it will set the :post relation to the database handle by this
                # subclass
                def muliple_relations
                  self.class.muliple_relations
                end
              end
            end)
            # Set the relations for the current database
            Object.const_get("#{self.name}#{db.capitalize}").muliple_relations
          end
        end if database_list.any?
      end
    end
  end


  private

  def run_setup
    Object.class_eval do
      def self.const_missing(c)
        matches = []
        db_matches = []
        MultipleDbs::DBS.each do |db|
          matches << c.to_s.scan(
          Regexp.new('(([A-Z]){1}([a-zA-Z]|[0-9])*)+' + db.to_s.camelize + '$')
          )
          db_matches << db
          break if matches.flatten.any?
        end
        const_temp = Object.const_get(matches.first).mdb(db_matches.last) if matches.flatten!.any?
        MultipleDbs.validate_connection(db_matches.last) if matches.any? and const_temp.to_s.eql?(c.to_s)
        return const_temp if matches.any? and const_temp.to_s.eql?(c.to_s)
        super
      end
    end if Rails.env.development? and defined? MultipleDbs and defined? MultipleDbs::DBS

    DBS.each do |db|
      Object.const_set("DBConnection" + db.to_s.camelize , Class.new do
        attr_accessor :connection
        @connection = YAML::load(ERB.new(File.read(Rails.root.join("config/multiple_dbs", db.to_s.downcase  + "_database.yml"))).result)[Rails.env]
        def self.connection
          @connection
        end
      end)
    end

    DBS.each do |db|
      conn_config = const_get("DBConnection" + db.to_s.camelize).connection
      if conn_config["database"] != ActiveRecord::Base.connection_config[:database]
        conn_klass = Object.const_set("Conn" + db.to_s.camelize, Class.new(ApplicationRecord))
        conn_klass.establish_connection conn_config
        conn_klass.connection
      else
        Object.const_set("Conn" + db.to_s.camelize, ActiveRecord::Base)
      end
    end

    ActiveRecord::Base.clear_all_connections!
  end
  module_function :run_setup

end

# If running in development mode, rails use Kernel#load to load our code.
# Is good, it allows us to make changes in files and see the changes in our
# server/console instantly but the subclasses that we create for each one of
# your models will not be available until you call the model...
# So this piece of code override const_missing if you are running rails in
# development and find the constants that you are looking for
# (the multiple_dbs constants) behind the scenes
