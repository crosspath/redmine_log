module LogPlugin
  class LogMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      ret = @app.call(env) # [code Fixnum, headers Hash, body String]
      Log.save_log(env, ret[0]) if Setting.plugin_redmine_log['log_enabled']
      ret
    rescue => e
      Rails.logger.error "#{e.to_s}\r\n#{e.backtrace.join("\r\n")}"
      raise e
    end
  end
end

RedmineApp::Application.config.middleware.insert_after ActionDispatch::Static, LogPlugin::LogMiddleware
