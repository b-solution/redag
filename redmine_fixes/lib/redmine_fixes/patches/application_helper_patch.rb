require_dependency 'application_helper'

module RedmineFixes
  module Patches

    module ApplicationHelperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          alias_method_chain :link_to_project, :changes

        end
      end

      module InstanceMethods
        def link_to_project_with_changes(project, options={}, html_options = nil)
          if project.archived?
            h(project.name)
          else
            link_to project.name, project_issues_path(project, {:only_path => true}.merge(options)), html_options
          end
        end
      end

    end

  end
end
