class Log < ActiveRecord::Base
  SESSION_LENGTH = 30

  attr_accessible :method, :query, :parameters, :controller, :response_code, :referer, :referer_controller, :first_id

  belongs_to :user

  def self.save_log(env, code)
    parameters = env['action_dispatch.request.path_parameters']
    session = env['rack.session']
    ref = env['action_controller.instance'].try(:back_url)
    now = DateTime.now

    l = Log.new(
      method: env['REQUEST_METHOD'],
      query: env['REQUEST_URI'],
      parameters: parameters.to_json,
      controller: parameters[:controller],
      response_code: code,
      referer: ref,
      referer_controller: (ref && Rails.application.routes.recognize_path(ref)[:controller] rescue '-')
    )
    l.user = User.where(id: session['user_id']).first if session && session['user_id']
    # first_id - первый элемент в цепочке
    first_id = Log.where(user_id: l.user_id, created_at: (now.advance minutes: -SESSION_LENGTH) .. now).order(id: :desc).first.try(:first_id)
    l.first_id = first_id if first_id
    l.save
    l.first_id = l.id unless first_id
    l.save
  end
end
