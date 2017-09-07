class ApplicationController < ActionController::Base
		# def mdb_name
      #   Thread.current[:mdb_name] ||= ... somthing that gives you the database name, like: 'db1' or 'client1_database'
      # end
      # before_filter do
      #   MultipleDbs.validate_connection(mdb_name)
      # end
  protect_from_forgery with: :exception
end
