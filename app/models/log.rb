class Log < ActiveRecord::Base
  attr_accessible :method, :query, :parameters, :controller, :response_code, :referer
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
      referer: env['action_controller.instance'].try(:back_url)
    )
    l.user = User.where(id: session['user_id']).first if session && session['user_id']
    l
  end
end
