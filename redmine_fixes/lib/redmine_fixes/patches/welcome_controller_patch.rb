require_dependency 'welcome_controller'

module RedmineFixes
  module Patches

    module WelcomeControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          # before_filter :get_projects
          # before_filter :get_issues

          alias_method_chain :index, :new_redirect

          helper :projects
          include ProjectsHelper

          helper :custom_fields
          include CustomFieldsHelper
          helper :issue_relations
          include IssueRelationsHelper
          helper :queries
          include QueriesHelper
          helper :sort
          include SortHelper
          include IssuesHelper
        end
      end

      module InstanceMethods

        def index_with_new_redirect
          if User.current.allowed_to_globally?(:view_agile_queries)
            redirect_to '/agile/board'
          else
            get_issues
            get_projects
            index_without_new_redirect
          end
        end

        def get_projects
          @projects_box = Project.visible.order('lft').all
        end

        def get_issues
          # hash = {"set_filter"=>"1", "f"=>["status_id", "assigned_to_id", ""], "op"=>{"status_id"=>"=", "assigned_to_id"=>"="}, "v"=>{"status_id"=>["2"], "assigned_to_id"=>["me"]}, "c"=>["project", "status", "subject", "assigned_to", "cf_1", "done_ratio", "due_date", "estimated_hours"], "group_by"=>"" }
          hash = {"set_filter"=>"1", "f"=>["assigned_to_id", ""], "op"=>{"assigned_to_id"=>"="}, "v"=>{"assigned_to_id"=>["me"]}, "c"=>["project", "status", "subject", "assigned_to", "cf_1", "done_ratio", "due_date", "estimated_hours"], "group_by"=>"" }
          params.merge!(hash)
          params.merge!({"sort"=>"updated_on:desc,id:desc"})
          retrieve_query
          sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
          sort_update(@query.sortable_columns)
          @query.sort_criteria = sort_criteria.to_a
          if @query.valid?
            @issues = @query.issues(:order => sort_clause)
          end
        end
      end

    end

  end
end
