Redmine::Plugin.register :redmine_notification do
  name 'Redmine Notification plugin'
  author 'Bilel KEDIDI'
  description 'This is a plugin for Redmine'
  version '0.0.1'

end

Rails.application.config.to_prepare do
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_issues_show_details_bottom, :partial=> 'issues/notification'
  end
  Issue.send(:include, RedmineNotification::IssuePatch)
end
