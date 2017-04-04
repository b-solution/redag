require_dependency 'issue'

module RedmineFixes
  module Patches

    module IssuePatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          def copy?
            return false unless Setting.plugin_redmine_fixes[:allow_copy_link]
            @copied_from.present?
          end
        end
      end

      module InstanceMethods


      end

    end

  end
end
