namespace :redmine do
  namespace :notification_plugin do
    task :send_notifications => :environment do
      Mailer.with_synched_deliveries do
        NotificationMailer.reminder_notifications
      end
    end
  end
end
