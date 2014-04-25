# coding: UTF-8

Redmine::Plugin.register :log do
  name 'Log plugin'
  author 'Ночевнов Евгений'
  description 'Регистрация обращений к Redmine'
  version '0.0.4'
  author_url 'http://crosspath.bplaced.net'
  url 'https://github.com/crosspath/redmine_log'
  
  settings default: {
    log_enabled: true
  }, partial: 'settings/log'
  
  require_relative 'lib/action_dispatch/middleware/request_id'
end

ActionDispatch::Callbacks.to_prepare do
  Setting.plugin_log = {} unless Setting.plugin_log.is_a?(Hash)
end
