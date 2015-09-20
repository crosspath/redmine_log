class Log < ActiveRecord::Base
  SESSION_LENGTH = 30

  attr_accessible :http_method, :query, :parameters, :controller, :action, :response_code, :referer, :referer_controller, :first_id

  belongs_to :user

  scope :interval, -> (from = nil, to = from + 1.day) { from.nil? ? where(nil) : where(created_at: from .. to) }

  def self.save_log(env, code)
    parameters = env['action_dispatch.request.path_parameters']
    session = env['rack.session']
    ref = env['action_controller.instance'].try(:back_url)
    ref_controller = find_ref_controller(ref)

    l = Log.new(
      http_method: env['REQUEST_METHOD'],
      query: env['REQUEST_URI'],
      parameters: parameters.to_json,
      controller: parameters[:controller],
      action: parameters[:action],
      response_code: code,
      referer: ref,
      referer_controller: ref_controller
    )
    l.user = User.find_by(id: session['user_id']) if session && session['user_id']
    first_in_session = find_current_session_start_for_user(l.user) if l.user.present?

    l.first_id = first_in_session.first_id if first_in_session
    l.save
    l.update(first_id: l.id) unless first_in_session
  end
  
  def self.find_ref_controller(ref)
    return nil if ref.blank?
    
    path = ref.gsub(/[^\w[[:punct:]]=]+/){ |x| URI.encode_www_form_component(x) }
    path && Rails.application.routes.recognize_path(path)[:controller]
  rescue
    nil
  end
  
  # first_id указывает на первый элемент в сессии
  def self.find_current_session_start_for_user(user)
    now = DateTime.now
    cond = {user_id: user.id, created_at: (now - SESSION_LENGTH.minutes) .. now}
    Log.select('id, first_id').order(id: :desc).find_by(cond)
  end
  
  def safe_parse_parameters
    if parameters.present?
      JSON.parse(parameters)
    else
      nil
    end
  rescue JSON::ParserError
    nil
  end
  
  def controller_and_action
    "#{controller}##{action}"
  end
end
