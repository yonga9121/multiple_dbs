module MultipleDbs
  # Your databases.
	DBS=[:your_database, :your_database2, :your_database3]

  module DbConnection
    # DbConnection Constants.
		DBS.each do |db|
      const_set(db.to_s.capitalize , Class.new do
        attr_accessor :connection
        @connection = YAML::load(ERB.new(File.read(Rails.root.join("config/multiple_dbs", db.to_s.downcase  + "_database.yml"))).result)[Rails.env]
        def self.connection
          @connection
        end
      end)
    end
  end

end
