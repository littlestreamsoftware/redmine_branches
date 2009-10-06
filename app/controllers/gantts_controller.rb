class GanttsController < ApplicationController
  before_filter :find_optional_project

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :gantt
  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  include Redmine::Export::PDF
  
  def show
    @gantt = Redmine::Helpers::Gantt.new(params)
    retrieve_query
    @query.group_by = nil
    if @query.valid?
      events = []
      # Versions
      versions = @query.versions(:conditions => ["effective_date BETWEEN ? AND ?", @gantt.date_from, @gantt.date_to])
      events += versions

      # Issues that have start dates and end dates but don't have a version
      # from above
      #
      # OPTIMIZE: should filter out issues on the versions above in SQL instead of Ruby
      issues = Issue.for_gantt_with_start_and_end_dates(@query, @gantt.date_from, @gantt.date_to)
 
      # Issues that don't have a due date but that are assigned to a version with a date
      issues += Issue.for_gantt_with_start_and_assigned_to_version_with_date(@query, @gantt.date_from, @gantt.date_to)

      events += issues.reject {|i| versions.include?(i.fixed_version)}
      @gantt.events = events
      @gantt.project = @project
      @gantt.query = @query

    end
    
    basename = (@project ? "#{@project.identifier}-" : '') + 'gantt'
    
    respond_to do |format|
      format.html { render :action => "show", :layout => !request.xhr? }
      format.png  { send_data(@gantt.to_image, :disposition => 'inline', :type => 'image/png', :filename => "#{basename}.png") } if @gantt.respond_to?('to_image')
      format.pdf  { send_data(gantt_to_pdf(@gantt, @project), :type => 'application/pdf', :filename => "#{basename}.pdf") }
    end
  end

end
