module LogPlugin
  class LogMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      if Setting.plugin_redmine_log['log_enabled']
        call_and_save_log(env)
      else
        @app.call(env)
      end
    end
    
    protected
    
    def call_and_save_log(env)
      time_start = Time.now
      ret = @app.call(env) # [code Fixnum, headers Hash, body String]
      duration = Time.now - time_start
      Log.save_log(env, ret[0], duration)
      ret
    rescue => e
      Rails.logger.error "#{e.to_s}\r\n#{e.backtrace.join("\r\n")}"
      raise e
    end
  end
end

RedmineApp::Application.config.middleware.insert_after ActionDispatch::Static, LogPlugin::LogMiddleware
