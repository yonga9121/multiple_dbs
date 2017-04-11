module MultipleDbs
  # Your databases.
	DBS=[:db1, :db2]

  class DbConnection
    # Databases connections.
		DBS.each do |db|
      const_set(db.to_s.capitalize, Class.new do
         attr_accessor :connection
         @connection = YAML::load(ERB.new(File.read(Rails.root.join("config/multiple_dbs",db.to_s + "_database.yml"))).result)[Rails.env]
         def self.connection
           @connection
         end
      end)
    end
  end
end
