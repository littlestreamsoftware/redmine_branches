class GanttsController < ApplicationController
  before_filter :find_optional_project

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

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
      # Issues that have start and due dates
      events += Issue.for_gantt_with_start_and_end_dates(@query, @gantt.date_from, @gantt.date_to)

      # Issues that don't have a due date but that are assigned to a version with a date
      events += Issue.for_gantt_with_start_and_assigned_to_version_with_date(@query, @gantt.date_from, @gantt.date_to)

      # Versions
      events += @query.versions(:conditions => ["effective_date BETWEEN ? AND ?", @gantt.date_from, @gantt.date_to])
                                   
      @gantt.events = events
    end
    
    basename = (@project ? "#{@project.identifier}-" : '') + 'gantt'
    
    respond_to do |format|
      format.html { render :action => "show", :layout => !request.xhr? }
      format.png  { send_data(@gantt.to_image, :disposition => 'inline', :type => 'image/png', :filename => "#{basename}.png") } if @gantt.respond_to?('to_image')
      format.pdf  { send_data(gantt_to_pdf(@gantt, @project), :type => 'application/pdf', :filename => "#{basename}.pdf") }
    end
  end

end
