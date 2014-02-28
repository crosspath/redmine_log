# coding: UTF-8

Redmine::Plugin.register :log do
  name 'Log plugin'
  author 'Ночевнов Евгений'
  description 'Регистрация обращений к Redmine'
  version '0.0.3'
  author_url 'http://crosspath.bplaced.net'
  url 'https://github.com/crosspath/redmine_log'
  
  require_relative 'config/servers'
  require_relative 'lib/action_dispatch/middleware/request_id'
  require_relative 'lib/application_controller_patch'
end
