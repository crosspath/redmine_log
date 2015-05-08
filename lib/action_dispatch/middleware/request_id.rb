require 'bundler'
gem = Bundler.rubygems.find_name('actionpack').first
require "#{gem.full_gem_path}/#{gem.require_path}/action_dispatch/middleware/request_id.rb"

module ActionDispatch
  class RequestId
    def call_with_log(env)
      ret = call_without_log(env)
      if Setting.plugin_redmine_log['log_enabled']
        Log.save_log(env, ret[0])
      end
      ret
    rescue => e
      Rails.logger.error e.to_s+"\r\n"+e.backtrace.join("\r\n")
      raise e
    end
    
    alias_method_chain :call, :log
  end
end
