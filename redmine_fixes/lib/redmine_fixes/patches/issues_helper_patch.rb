require_dependency 'issues_helper'

module RedmineFixes
  module Patches

    module IssuesHelperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          def email_issue_attributes(issue, user)
            items = []
            %w(author status priority assigned_to category fixed_version due_date).each do |attribute|
              unless issue.disabled_core_fields.include?(attribute+"_id")
                if attribute == 'due_date'
                  due_date = issue.send( attribute) ? issue.send(attribute).strftime('%d.%m.%Y') : nil
                  items << "#{l("field_#{attribute}")}: #{due_date}"
                else
                  items << "#{l("field_#{attribute}")}: #{issue.send attribute}"
                end
              end
            end
            issue.visible_custom_field_values(user).each do |value|
              items << "#{value.custom_field.name}: #{show_value(value, false)}"
            end
            items
          end
        end
      end

      module InstanceMethods


      end

    end

  end
end

