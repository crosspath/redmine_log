class Log < ActiveRecord::Base
  belongs_to :user
  def self.new_log(env, code)
    parameters = env['action_dispatch.request.path_parameters']
    session = env['rack.session']
    l = Log.new(
      method: env['REQUEST_METHOD'],
      query: env['REQUEST_URI'],
      parameters: parameters.to_json,
      controller: parameters[:controller],
      response_code: code,
      referer: env['action_controller.instance'].back_url
    )
    l.user = User.try_find(session['user_id']) if session && session['user_id']
    l
  end
end

module LogPlugin
  module UserPatch
    def self.included(base)
      base.class_eval { has_many :logs }
    end
  end
end

ActionDispatch::Callbacks.to_prepare do
  User.send(:include, LogPlugin::UserPatch) unless User.included_modules.include?(LogPlugin::UserPatch)
end
