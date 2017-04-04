require_dependency 'issues_controller'

module RedmineFixes
  module Patches

    module IssuesControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          alias_method_chain :update, :new_redirect
          alias_method_chain :redirect_after_create, :new_redirect
          alias_method_chain :destroy, :new_redirect
          before_filter :new_sort, only: [:index]

        end
      end

      module InstanceMethods

        def new_sort
          params.reverse_merge!("sort"=>"cf_1,id:desc")
        end

        def update_with_new_redirect
          return unless update_issue_from_params
          @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
          saved = false
          begin
            saved = save_issue_with_child_records
          rescue ActiveRecord::StaleObjectError
            @conflict = true
            if params[:last_journal_id]
              @conflict_journals = @issue.journals_after(params[:last_journal_id]).to_a
              @conflict_journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
            end
          end

          if saved
            render_attachment_warning_if_needed(@issue)
            flash[:notice] = l(:notice_successful_update) unless @issue.current_journal.new_record?

            respond_to do |format|
              format.html {  project = @issue.project
              if project.module_enabled?("agile") && User.current.allowed_to?(:view_agile_queries, project )
                if session[:board_project_id]
                  redirect_back_or_default "/projects/#{project.identifier}/agile/board"
                else
                  redirect_back_or_default "/agile/board"
                end
              else
                redirect_back_or_default project_issues_path(project)
              end
              }
              format.api  { render_api_ok }
            end
          else
            respond_to do |format|
              format.html { render :action => 'edit' }
              format.api  { render_validation_errors(@issue) }
            end
          end
        end


        def redirect_after_create_with_new_redirect
          if params[:continue]
            attrs = {:tracker_id => @issue.tracker, :parent_issue_id => @issue.parent_issue_id}.reject {|k,v| v.nil?}
            if params[:project_id]
              redirect_to new_project_issue_path(@issue.project, :issue => attrs)
            else
              attrs.merge! :project_id => @issue.project_id
              redirect_to new_issue_path(:issue => attrs)
            end
          else
            project = @issue.project
            if project.module_enabled?("agile") && User.current.allowed_to?(:view_agile_queries, project )
              redirect_to "/projects/#{project.identifier}/agile/board"
            else
              issue_path(@issue)
            end
          end
        end


        def destroy_with_new_redirect
          raise Unauthorized unless @issues.all?(&:deletable?)
          @hours = TimeEntry.where(:issue_id => @issues.map(&:id)).sum(:hours).to_f
          if @hours > 0
            case params[:todo]
              when 'destroy'
                # nothing to do
              when 'nullify'
                TimeEntry.where(['issue_id IN (?)', @issues]).update_all('issue_id = NULL')
              when 'reassign'
                reassign_to = @project.issues.find_by_id(params[:reassign_to_id])
                if reassign_to.nil?
                  flash.now[:error] = l(:error_issue_not_found_in_project)
                  return
                else
                  TimeEntry.where(['issue_id IN (?)', @issues]).
                      update_all("issue_id = #{reassign_to.id}")
                end
              else
                # display the destroy form if it's a user request
                return unless api_request?
            end
          end
          @issues.each do |issue|
            begin
              issue.reload.destroy
            rescue ::ActiveRecord::RecordNotFound # raised by #reload if issue no longer exists
              # nothing to do, issue was already deleted (eg. by a parent)
            end
          end
          respond_to do |format|
            format.html {
              if @project.module_enabled?("agile") && User.current.allowed_to?(:view_agile_queries, @project )
                if session[:board_project_id]
                  redirect_back_or_default "/projects/#{@project.identifier}/agile/board"
                else
                  redirect_back_or_default "/agile/board"
                end
              else
                redirect_back_or_default _project_issues_path(@project)
              end
            }
            format.api  { render_api_ok }
          end
        end

      end

    end

  end
end
