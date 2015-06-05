class Log < ActiveRecord::Base
  SESSION_LENGTH = 30

  attr_accessible :method, :query, :parameters, :controller, :response_code, :referer, :referer_controller, :first_id

  belongs_to :user

  scope :interval, -> (from = nil, to = from + 1.day) { from.nil? ? where(nil) : where(created_at: from .. to) }

  def self.save_log(env, code)
    parameters = env['action_dispatch.request.path_parameters']
    session = env['rack.session']
    ref = env['action_controller.instance'].try(:back_url)

    now = DateTime.now
    method = env['REQUEST_METHOD']

    ref_controller = if ref
                       a = ref && ref.gsub(/[^\w[[:punct:]]=]+/){ |x| URI.encode_www_form_component(x) }
                       (a && Rails.application.routes.recognize_path(a)[:controller] rescue '-')
                     end

    l = Log.new(
      method: method,
      query: env['REQUEST_URI'],
      parameters: parameters.to_json,
      controller: parameters[:controller],
      response_code: code,
      referer: ref,
      referer_controller: ref_controller
    )
    l.user = User.where(id: session['user_id']).first if session && session['user_id']

    # first_id - первый элемент в цепочке
    cond = {user_id: l.user_id, created_at: (now.advance minutes: -SESSION_LENGTH) .. now}
    first_id = Log.select('id, first_id').where(cond).order(id: :desc).first.try(:first_id)

    l.first_id = first_id if first_id
    l.save
    unless first_id
      l.first_id = l.id
      l.save
    end
  end
end
