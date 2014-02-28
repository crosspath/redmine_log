module RedmineApp
  class Application < Rails::Application

    config.servers = {
      development: %w!
        10.8.34.253
        redmine.duser032.test 10.8.34.32 dev032
        redmine.duser037.test 10.8.34.37 dev037
        dev!
    }

  end
end
