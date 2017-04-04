class NoMailConfiguration < RuntimeError;
end


class NotificationMailer < Mailer
  include Redmine::I18n

  prepend_view_path "#{Redmine::Plugin.find("redmine_notification").directory}/app/views"

  def self.reminder_notifications
    unless ActionMailer::Base.perform_deliveries
      raise NoMailConfiguration.new(l(:text_email_delivery_not_configured))
    end
    issues = self.find_issues_recurring
    # issues.each { |issue| self.insert(data, issue) }
    # issues.each { |issue| issue.last_notification = DateTime.now; issue.save }
    issues.each do |issue|
      reminder_notification(issue, 0).deliver
    end

    issues = self.find_issue_due_soon
    issues.each do |issue|
      reminder_notification(issue, 1).deliver
    end
  end

  def reminder_notification(issue, type)
    @type = type
    user = issue.assigned_to
    # Only send notifications if the user has requested them or they are
    # activated by default.
    set_language_if_valid user.language
    # puts "User: #{user.name}. Setting for notification: #{user.reminder_notification}"
    @project = issue.project
    @issue = issue
    # @issues_url = url_for(:controller => 'issues', :action => 'index',
    #                       :set_filter => 1, :assigned_to_id => user.id,
    #                       :sort => 'due_date:asc')

    subject = type == 0 ? "#{l(:reminder_mail_subject_recurring)} #{issue.subject}" : "#{l(:reminder_mail_subject_due_soon)} #{issue.subject}"
    mail :to => user.mail, :subject => subject
  end

  def self.find_issue_due_soon
    scope = Issue.includes(:project).open.where("#{Issue.table_name}.assigned_to_id IS NOT NULL" +
                                                    " AND #{Project.table_name}.status = #{Project::STATUS_ACTIVE}" +
                                                    " AND (#{Issue.table_name}.due_date IS NOT NULL AND #{Issue.table_name}.due_date = ?)" , (Date.today + 1.day).to_s)
    issues = scope.all(:include => [:status, :assigned_to, :project, :tracker])
    issues
  end

  def self.find_issues_recurring
    scope = Issue.includes(:project).open.where("#{Issue.table_name}.assigned_to_id IS NOT NULL" +
                                                  " AND #{Project.table_name}.status = #{Project::STATUS_ACTIVE}" +
                                                  " AND (#{Issue.table_name}.reminder_date IS NOT NULL AND #{Issue.table_name}.reminder_option IS NOT NULL)")
    issues = scope.all(:include => [:status, :assigned_to, :project, :tracker])
    issues.select{ |issue|
      issue.can_notify?
    }
  end
  private

  def self.insert(data, issue)
    data[issue.assigned_to] ||= {}
    data[issue.assigned_to][issue.project] ||= []
    data[issue.assigned_to][issue.project] << issue
  end
end
