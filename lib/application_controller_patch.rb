module ApplicationControllerPatch
  def self.included(base)
    base.class_eval do
      cattr_accessor :renv
      class << self
        protected :renv=
        include ApplicationControllerPatch::ClassMethods
      end
    end
  end
  
  module ClassMethods
    def servers(options={})
      server_name = %w(HOSTNAME SERVER_ADDR SERVER_NAME).map { |key| ENV[key] }.compact
      @@renv ||= :production
      options.each do |env, srv|
        @@renv = env.to_sym if ENV['RAILS_ENV'] == env.to_s || (server_name & srv).present?
      end
    end
    def prod?
      @@renv ||= :production
      @@renv == :production
    end
    def dev?
      @@renv == :development
    end
    def test?
      @@renv == :test
    end
  end
end

ActionDispatch::Callbacks.to_prepare do
  unless ApplicationController.included_modules.include?(ApplicationControllerPatch)
    ApplicationController.send(:include, ApplicationControllerPatch)
    ApplicationController.servers(RedmineApp::Application.config.servers)
  end
end
