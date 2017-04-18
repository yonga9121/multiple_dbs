module MultipleDbs
  class Railtie < Rails::Railtie

    rake_tasks do
      load 'tasks/multiple_dbs_tasks.rake'
    end

  end
end
