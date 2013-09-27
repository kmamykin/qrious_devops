module QriousDevops
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/databases.rake"
      load "tasks/deploy.rake"
    end
  end
end
