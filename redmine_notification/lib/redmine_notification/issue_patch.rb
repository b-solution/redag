require_dependency 'issue'
module RedmineNotification
  module IssuePatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        # Same as typing in the class.
        unloadable # Send unloadable so it will not be unloaded in development.
        safe_attributes 'reminder_date', 'reminder_option'
      end
    end
  end

  module InstanceMethods
    def can_notify?
      return false if reminder_date.nil? or reminder_option.nil?

      # -  single reminder
      # -  weekly reminder
      # -  two weeks reminder
      # -  monthly reminder
      # -  two months reminder
      # -  three months reminder
      # -  six month reminder
      case reminder_option
        when 'single'
          return true if reminder_date == Date.today
        when 'weekly'
          return time_include_by_week(reminder_date, 1)
        when 'two_weeks'
          return time_include_by_week(reminder_date, 2)
        when 'monthly'
          return time_include_by_month(reminder_date, 1)
        when 'two_months'
          return time_include_by_month(reminder_date, 2)
        when 'three_months'
          return time_include_by_month(reminder_date, 3)
        when 'six_months'
          return time_include_by_month(reminder_date, 6)
        else
          return false
      end
      false
    end


    def time_include_by_month(start_date, number_of_month)
      date = start_date + (Date.today.year - start_date.year).years # adjust the same year
      today = Date.today
      while today >= date
        return true if today == date
        date  = date + number_of_month.months
      end
      false
    end

    def time_include_by_week(start_date, number_of_week)
      date = start_date + ((Date.today.year - start_date.year)*52).weeks # adjust the same year
      today = Date.today
      while today >= date
        return true if today == date
        date  = date + number_of_week.weeks
      end
      false
    end
  end
end
