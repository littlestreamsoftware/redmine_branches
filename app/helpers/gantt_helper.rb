# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module GanttHelper
  # Returns the number of rows that will be rendered on the Gantt chart
  def number_of_rows
    if @project
      return number_of_rows_on_project(@project)
    else
      Project.roots.inject(0) do |total, project|
        total += number_of_rows_on_project(project)
      end
    end
  end

  # Returns the number of rows that will be used to list a project on
  # the Gantt chart.  This will recurse for each subproject.
  def number_of_rows_on_project(project)
    # One Root project
    count = 1
    # Issues without a Version
    count += project.issues.for_gantt.without_version.with_query(@query).count

    # Versions
    count += project.versions.count

    # Issues on the Versions
    project.versions.each do |version|
      count += version.fixed_issues.for_gantt.with_query(@query).count
    end

    # Subprojects
    project.children.each do |subproject|
      count += number_of_rows_on_project(subproject)
    end

    count
  end
  
  def number_of_issues_on_versions(gantt)
    versions = gantt.events.collect {|event| (event.is_a? Version) ? event : nil}.compact

    versions.sum {|v| v.fixed_issues.for_gantt.with_query(@query).count}
  end
  
  def tasks_subjects(options={})
    options = {:indent => 4, :render => :subject}.merge(options)

    output = ''
    if @project
      output << tasks_subjects_for_project(@project, options)
    else
      Project.roots.each do |project|
        output << tasks_subjects_for_project(project, options)
      end
    end

    output
  end

  def tasks_subjects_for_project(project, options={})
    output = ''
    # Project Header
    output << if options[:render] == :subject
                subject_for_project(project, options)
              else
                # :line
                line_for_project(project, options)
              end
    
    options[:top] += 20
    options[:indent] += 20
    
    # Second, Issues without a version
    issues = project.issues.for_gantt.without_version.with_query(@query)
    if issues
      output << tasks_subjects_for_issues(issues, options)
    end

    # Third, Versions
    project.versions.each do |version|
      output << tasks_subjects_for_version(version, options)
    end

    # Fourth, subprojects
    project.children.each do |project|
      output << tasks_subjects_for_project(project, options)
    end

    # Remove indent to hit the next sibling
    options[:indent] -= 20 
    
    output
  end

  def tasks_subjects_for_issues(issues, options={})
    output = ''
    issues.each do |i|
      output << if options[:render] == :subject
                  subject_for_issue(i, options)
                else
                  # :line
                  line_for_issue(i, options)
                end
      options[:top] += 20
    end
    output
  end

  def tasks_subjects_for_version(version, options={})
    output = ''
    # Version header
    output << if options[:render] == :subject
                  subject_for_version(version, options)
                else
                  # :line
                  line_for_version(version, options)
                end
      
    options[:top] += 20

    # Remove the project requirement for Versions because it will
    # restrict issues to only be on the current project.  This
    # ends up missing issues which are assigned to shared versions.
    @query.project = nil if @query.project
    
    issues = version.fixed_issues.for_gantt.with_query(@query)
    if issues
      output << tasks_subjects_for_issues(issues, options.merge({:indent => options[:indent] + 20}))
      options[:top] += (20 * issues.length) # Pad the top for each issue displayed
    end

    output
  end

  def tasks(options)
    options = {:indent => 4, :render => :line}.merge(options)
    output = ''

    if @project
      output << tasks_subjects_for_project(@project, options)
    else
      Project.roots.each do |project|
        output << tasks_subjects_for_project(project, options)
      end
    end
    
    output
  end

  def subject_for_project(project, options)
    output = ''
    output << "<div style='position: absolute;line-height:1.2em;height:16px;top:#{options[:top]}px;left:#{options[:indent]}px;overflow:hidden;'><small>    "
    if project.is_a? Project
      output << '<span class="icon icon-projects">'
      output << link_to(h(project), {:controller => 'projects', :action => 'show', :id => project}, :class => "project")
      output << '</span>'
    else
      logger.warn "GanttHelper#tasks_subjects_for_project was not given a project"
    end
    output << "</small></div>"

    output
  end

  def line_for_project(project, options)
    # Nothing
    ''
  end

  def subject_for_version(version, options)
    output = ''
    output << "<div style='position: absolute;line-height:1.2em;height:16px;top:#{options[:top]}px;left:#{options[:indent]}px;overflow:hidden;'><small>    "
    if version.is_a? Version
      output << '<span class="icon icon-package">'
      output << link_to_version(version)
      output << '</span>'
    else
      logger.warn "GanttHelper#tasks_subjects_for_version was not given a version"
    end
    output << "</small></div>"

    output
  end

  def line_for_version(version, options)
    output = ''
    # Skip versions that don't have a start_date
    if version.is_a?(Version) && version.start_date
        i_left = ((version.start_date - @gantt.date_from)*options[:zoom]).floor

        output << "<div style='top:#{ options[:top] }px;left:#{ i_left }px;width:15px;' class='task milestone'>&nbsp;</div>"
        output << "<div style='top:#{ options[:top] }px;left:#{ i_left + 12 }px;background:#fff;' class='task'>"
		output << h("#{version.project} -") unless @project && @project == version.project
		output << "<strong>#{h version }</strong>"
      output << "</div>"
    end

    output

  end

  def subject_for_issue(issue, options)
    output = ''
    output << "<div style='position: absolute;line-height:1.2em;height:16px;top:#{options[:top]}px;left:#{options[:indent]}px;overflow:hidden;'><small>    "
    if issue.is_a? Issue
      output << '<span class="icon icon-issue">'
      output << h("#{issue.project} -") unless @project && @project == issue.project
      output << link_to_issue(issue)
      output << ":"
      output << h(issue.subject)
      output << '</span>'
    else
      logger.warn "GanttHelper#tasks_subjects_for_issues was not given an issue"
    end
    output << "</small></div>"
  end

  def line_for_issue(issue, options)
    output = ''
    # Skip issues that don't have a due_before (due_date or version's due_date)
    if issue.is_a?(Issue) && issue.due_before
      # Handle nil start_dates, rare but can happen.
      i_start_date =  if issue.start_date && issue.start_date >= @gantt.date_from
                        issue.start_date
                      else
                        @gantt.date_from
                      end

      i_end_date = ((issue.due_before && issue.due_before <= @gantt.date_to) ? issue.due_before : @gantt.date_to )
      i_done_date = i_start_date + ((issue.due_before - i_start_date+1)*issue.done_ratio/100).floor
      i_done_date = (i_done_date <= @gantt.date_from ? @gantt.date_from : i_done_date )
      i_done_date = (i_done_date >= @gantt.date_to ? @gantt.date_to : i_done_date )
      
      i_late_date = [i_end_date, Date.today].min if i_start_date < Date.today
      
      i_left = ((i_start_date - @gantt.date_from)*options[:zoom]).floor 	
      i_width = ((i_end_date - i_start_date + 1)*options[:zoom]).floor - 2                  # total width of the issue (- 2 for left and right borders)
      d_width = ((i_done_date - i_start_date)*options[:zoom]).floor - 2                     # done width
      l_width = i_late_date ? ((i_late_date - i_start_date+1)*options[:zoom]).floor - 2 : 0 # delay width
      css = "task " + (i.leaf? ? 'leaf' : 'parent')

      
      output << "<div style='top:#{ options[:top] }px;left:#{ i_left }px;width:#{ i_width }px;' class='#{css} task task_todo'>&nbsp;</div>"
      if l_width > 0
        output << "<div style='top:#{ options[:top] }px;left:#{ i_left }px;width:#{ l_width }px;' class='#{css} task task_late'>&nbsp;</div>"
      end
      if d_width > 0
        output<< "<div style='top:#{ options[:top] }px;left:#{ i_left }px;width:#{ d_width }px;' class='#{css} task task_done'>&nbsp;</div>"
      end
      output << "<div style='top:#{ options[:top] }px;left:#{ i_left + i_width + 5 }px;background:#fff;' class='#{css} task'>"
      output << issue.status.name
      output << ' '
      output << (issue.done_ratio).to_i.to_s
      output << "%"
      output << "</div>"

      output << "<div class='tooltip' style='position: absolute;top:#{ options[:top] }px;left:#{ i_left }px;width:#{ i_width }px;height:12px;'>"
      output << '<span class="tip">'
      output << render_issue_tooltip(issue)
      output << "</span></div>"
    else
      logger.warn "GanttHelper#line_for_issue was not given an issue"
    end

    output
  end
end
