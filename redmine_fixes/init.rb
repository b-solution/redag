Redmine::Plugin.register :redmine_fixes do
  name 'Redmine Fixes plugin'
  author 'Bilel Kedidi'
  description 'This is a plugin for Redmine'
  version '1.0.0'

  settings :default => {
      :allow_copy_link => false
  }, :partial => 'settings/redmine_fixes/settings'

end

Rails.application.config.to_prepare do
  IssuesController.send(:include, RedmineFixes::Patches::IssuesControllerPatch )
  Issue.send(:include, RedmineFixes::Patches::IssuePatch )
  IssuesHelper.send(:include, RedmineFixes::Patches::IssuesHelperPatch )
  WelcomeController.send(:include, RedmineFixes::Patches::WelcomeControllerPatch )
  ApplicationHelper.send(:include, RedmineFixes::Patches::ApplicationHelperPatch )
end

class WelcomeControllerHook < Redmine::Hook::ViewListener
  render_on :view_welcome_index_left,
            :partial => 'hooks/view_welcome_index_left'
  render_on :view_welcome_index_right,
            :partial => 'hooks/view_welcome_index_right'
end