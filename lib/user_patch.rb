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
