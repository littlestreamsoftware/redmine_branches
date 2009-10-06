# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

module Redmine
  module Helpers
    # Simple class to handle gantt chart data
    class Gantt
      include ERB::Util

      attr_reader :year_from, :month_from, :date_from, :date_to, :zoom, :months, :events
      attr_accessor :query
      attr_accessor :project
      attr_accessor :view
      
      def initialize(options={})
        options = options.dup
        @events = []
        
        if options[:year] && options[:year].to_i >0
          @year_from = options[:year].to_i
          if options[:month] && options[:month].to_i >=1 && options[:month].to_i <= 12
            @month_from = options[:month].to_i
          else
            @month_from = 1
          end
        else
          @month_from ||= Date.today.month
          @year_from ||= Date.today.year
        end
        
        zoom = (options[:zoom] || User.current.pref[:gantt_zoom]).to_i
        @zoom = (zoom > 0 && zoom < 5) ? zoom : 2    
        months = (options[:months] || User.current.pref[:gantt_months]).to_i
        @months = (months > 0 && months < 25) ? months : 6
        
        # Save gantt parameters as user preference (zoom and months count)
        if (User.current.logged? && (@zoom != User.current.pref[:gantt_zoom] || @months != User.current.pref[:gantt_months]))
          User.current.pref[:gantt_zoom], User.current.pref[:gantt_months] = @zoom, @months
          User.current.preference.save
        end
        
        @date_from = Date.civil(@year_from, @month_from, 1)
        @date_to = (@date_from >> @months) - 1
      end
      
      
      def events=(e)
        @events = e
        # Adds all ancestors
        root_ids = e.select {|i| i.is_a?(Issue) && i.parent_id? }.collect(&:root_id).uniq
        if root_ids.any?
          # Retrieves all nodes
          parents = Issue.find_all_by_root_id(root_ids, :conditions => ["rgt - lft > 1"])
          # Only add ancestors
          @events += parents.select {|p| @events.detect {|i| i.is_a?(Issue) && p.is_ancestor_of?(i)}}
        end
        @events.uniq!
        # Sort issues by hierarchy and start dates
        @events.sort! {|x,y| 
          if x.is_a?(Issue) && y.is_a?(Issue)
            gantt_issue_compare(x, y, @events)
          else
            gantt_start_compare(x, y)
          end
        }
        # Removes issues that have no start or end date
        @events.reject! {|i| i.is_a?(Issue) && (i.start_date.nil? || i.due_before.nil?) }
        @events
      end
      
      def params
        { :zoom => zoom, :year => year_from, :month => month_from, :months => months }
      end
      
      def params_previous
        { :year => (date_from << months).year, :month => (date_from << months).month, :zoom => zoom, :months => months }
      end
      
      def params_next
        { :year => (date_from >> months).year, :month => (date_from >> months).month, :zoom => zoom, :months => months }
      end

            ### Extracted from the HTML view/helpers
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
          output << view.link_to_project(project)
          output << '</span>'
        else
          ActiveRecord::Base.logger.warn "GanttHelper#tasks_subjects_for_project was not given a project"
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
          output << view.link_to_version(version)
          output << '</span>'
        else
          ActiveRecord::Base.logger.warn "GanttHelper#tasks_subjects_for_version was not given a version"
        end
        output << "</small></div>"

        output
      end

      def line_for_version(version, options)
        output = ''
        # Skip versions that don't have a start_date
        if version.is_a?(Version) && version.start_date
          i_left = ((version.start_date - self.date_from)*options[:zoom]).floor

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
          output << view.link_to_issue(issue)
          output << ":"
          output << h(issue.subject)
          output << '</span>'
        else
          ActiveRecord::Base.logger.warn "GanttHelper#tasks_subjects_for_issues was not given an issue"
        end
        output << "</small></div>"
      end

      def line_for_issue(issue, options)
        output = ''
        # Skip issues that don't have a due_before (due_date or version's due_date)
        if issue.is_a?(Issue) && issue.due_before
          # Handle nil start_dates, rare but can happen.
          i_start_date =  if issue.start_date && issue.start_date >= self.date_from
                            issue.start_date
                          else
                            self.date_from
                          end

          i_end_date = ((issue.due_before && issue.due_before <= self.date_to) ? issue.due_before : self.date_to )
          i_done_date = i_start_date + ((issue.due_before - i_start_date+1)*issue.done_ratio/100).floor
          i_done_date = (i_done_date <= self.date_from ? self.date_from : i_done_date )
          i_done_date = (i_done_date >= self.date_to ? self.date_to : i_done_date )
          
          i_late_date = [i_end_date, Date.today].min if i_start_date < Date.today
          
          i_left = ((i_start_date - self.date_from)*options[:zoom]).floor 	
          i_width = ((i_end_date - i_start_date + 1)*options[:zoom]).floor - 2                  # total width of the issue (- 2 for left and right borders)
          d_width = ((i_done_date - i_start_date)*options[:zoom]).floor - 2                     # done width
          l_width = i_late_date ? ((i_late_date - i_start_date+1)*options[:zoom]).floor - 2 : 0 # delay width
          css = "task " + (i.leaf? ? 'leaf' : 'parent')
          
          output << "<div style='top:#{ options[:top] }px;left:#{ i_left }px;width:#{ i_width }px;' class='#{css} task_todo'>&nbsp;</div>"
          if l_width > 0
            output << "<div style='top:#{ options[:top] }px;left:#{ i_left }px;width:#{ l_width }px;' class='#{css} task_late'>&nbsp;</div>"
          end
          if d_width > 0
            output<< "<div style='top:#{ options[:top] }px;left:#{ i_left }px;width:#{ d_width }px;' class='#{css} task task_done'>&nbsp;</div>"
          end
          output << "<div style='top:#{ options[:top] }px;left:#{ i_left + i_width + 5 }px;background:#fff;' class='#{css}'>"
          output << issue.status.name
          output << ' '
          output << (issue.done_ratio).to_i.to_s
          output << "%"
          output << "</div>"

          output << "<div class='tooltip' style='position: absolute;top:#{ options[:top] }px;left:#{ i_left }px;width:#{ i_width }px;height:12px;'>"
          output << '<span class="tip">'
          output << view.render_issue_tooltip(issue)
          output << "</span></div>"
        else
          ActiveRecord::Base.logger.warn "GanttHelper#line_for_issue was not given an issue"
        end

        output
      end

      # END HTML

      
      # Generates a gantt image
      # Only defined if RMagick is avalaible
      def to_image(format='PNG')
        date_to = (@date_from >> @months)-1    
        show_weeks = @zoom > 1
        show_days = @zoom > 2
        
        subject_width = 320
        header_heigth = 18
        # width of one day in pixels
        zoom = @zoom*2
        g_width = (@date_to - @date_from + 1)*zoom
        g_height = 20 * (events.length + number_of_issues_on_versions) + 20
        headers_heigth = (show_weeks ? 2*header_heigth : header_heigth)
        height = g_height + headers_heigth
            
        imgl = Magick::ImageList.new
        imgl.new_image(subject_width+g_width+1, height)
        gc = Magick::Draw.new
        
        # Subjects
        image_subjects(gc, :top => (headers_heigth + 20), :events => events, :indent => 0)
    
        # Months headers
        month_f = @date_from
        left = subject_width
        @months.times do 
          width = ((month_f >> 1) - month_f) * zoom
          gc.fill('white')
          gc.stroke('grey')
          gc.stroke_width(1)
          gc.rectangle(left, 0, left + width, height)
          gc.fill('black')
          gc.stroke('transparent')
          gc.stroke_width(1)
          gc.text(left.round + 8, 14, "#{month_f.year}-#{month_f.month}")
          left = left + width
          month_f = month_f >> 1
        end
        
        # Weeks headers
        if show_weeks
        	left = subject_width
        	height = header_heigth
        	if @date_from.cwday == 1
        	    # date_from is monday
                week_f = date_from
        	else
        	    # find next monday after date_from
        		week_f = @date_from + (7 - @date_from.cwday + 1)
        		width = (7 - @date_from.cwday + 1) * zoom
                gc.fill('white')
                gc.stroke('grey')
                gc.stroke_width(1)
                gc.rectangle(left, header_heigth, left + width, 2*header_heigth + g_height-1)
        		left = left + width
        	end
        	while week_f <= date_to
        		width = (week_f + 6 <= date_to) ? 7 * zoom : (date_to - week_f + 1) * zoom
                gc.fill('white')
                gc.stroke('grey')
                gc.stroke_width(1)
                gc.rectangle(left.round, header_heigth, left.round + width, 2*header_heigth + g_height-1)
                gc.fill('black')
                gc.stroke('transparent')
                gc.stroke_width(1)
                gc.text(left.round + 2, header_heigth + 14, week_f.cweek.to_s)
        		left = left + width
        		week_f = week_f+7
        	end
        end
        
        # Days details (week-end in grey)
        if show_days
        	left = subject_width
        	height = g_height + header_heigth - 1
        	wday = @date_from.cwday
        	(date_to - @date_from + 1).to_i.times do 
              width =  zoom
              gc.fill(wday == 6 || wday == 7 ? '#eee' : 'white')
              gc.stroke('grey')
              gc.stroke_width(1)
              gc.rectangle(left, 2*header_heigth, left + width, 2*header_heigth + g_height-1)
              left = left + width
              wday = wday + 1
              wday = 1 if wday > 7
        	end
        end
    
        # border
        gc.fill('transparent')
        gc.stroke('grey')
        gc.stroke_width(1)
        gc.rectangle(0, 0, subject_width+g_width, headers_heigth)
        gc.stroke('black')
        gc.rectangle(0, 0, subject_width+g_width, g_height+ headers_heigth-1)
            
        # content
        top = headers_heigth + 20
        image_tasks(gc, :top => top, :zoom => zoom, :events => events, :subject_width => subject_width)
        
        # today red line
        if Date.today >= @date_from and Date.today <= date_to
          gc.stroke('red')
          x = (Date.today-@date_from+1)*zoom + subject_width
          gc.line(x, headers_heigth, x, headers_heigth + g_height-1)      
        end    
        
        gc.draw(imgl)
        imgl.format = format
        imgl.to_blob
      end if Object.const_defined?(:Magick)

      private

      # Helper methods to draw the image.
      # TODO: similar to the GanttHelper
      def image_subjects(gc, options = {})
        events = options.delete(:events)
        top = options.delete(:top)
        indent = options.delete(:indent) || 4

        gc.fill('black')
        gc.stroke('transparent')
        gc.stroke_width(1)
        events.each do |i|
          gc.text(indent, top + 2, (i.is_a?(Issue) ? i.subject : i.name))
          top = top + 20
          if i.is_a? Version
            issues = i.fixed_issues.for_gantt.with_query(query)
            image_subjects(gc, :top => top, :events => issues, :indent => indent + 30)
            top = top + (20 * issues.length) # Pad the top for each issue displayed
          end
        end
      end

      def image_tasks(gc, options = {})
        top = options.delete(:top)
        zoom = options.delete(:zoom)
        events = options.delete(:events)
        subject_width = options.delete(:subject_width)

        gc.stroke('transparent')
        events.each do |i|      
          if i.is_a?(Issue)       
            # Handle nil start_dates, rare but can happen.
            i_start_date =  if i.start_date && i.start_date >= @date_from
                              i.start_date
                            else
                              @date_from
                            end

            i_end_date = (i.due_before <= date_to ? i.due_before : date_to )        
            i_done_date = i_start_date + ((i.due_before - i_start_date+1)*i.done_ratio/100).floor
            i_done_date = (i_done_date <= @date_from ? @date_from : i_done_date )
            i_done_date = (i_done_date >= date_to ? date_to : i_done_date )        
            i_late_date = [i_end_date, Date.today].min if i_start_date < Date.today
            
            i_left = subject_width + ((i_start_date - @date_from)*zoom).floor 	
            i_width = ((i_end_date - i_start_date + 1)*zoom).floor                  # total width of the issue
            d_width = ((i_done_date - i_start_date)*zoom).floor                     # done width
            l_width = i_late_date ? ((i_late_date - i_start_date+1)*zoom).floor : 0 # delay width
      
            gc.fill('grey')
            gc.rectangle(i_left, top, i_left + i_width, top - 6)
            gc.fill('red')
            gc.rectangle(i_left, top, i_left + l_width, top - 6) if l_width > 0
            gc.fill('blue')
            gc.rectangle(i_left, top, i_left + d_width, top - 6) if d_width > 0
            gc.fill('black')
            gc.text(i_left + i_width + 5,top + 1, "#{i.status.name} #{i.done_ratio}%")
          elsif i.is_a? Version
            i_left = subject_width + ((i.start_date - @date_from)*zoom).floor
            gc.fill('green')
            gc.rectangle(i_left, top, i_left + 6, top - 6)        
            gc.fill('black')
            gc.text(i_left + 11, top + 1, i.name)
          else
            # Nothing
          end
          top = top + 20
          if i.is_a? Version
            # Remove the project requirement for Versions because it will
            # restrict issues to only be on the current project.  This
            # ends up missing issues which are assigned to shared versions.
            query.project = nil if query.project

            issues = i.fixed_issues.for_gantt.with_query(query)
            if issues
              image_tasks(gc, :top => top, :zoom => zoom, :events => issues, :subject_width => subject_width)
              top = top + (20 * issues.length) # Pad the top for each issue displayed
            end
          end
        end
        
        # today red line
        if Date.today >= @date_from and Date.today <= date_to
          gc.stroke('red')
          x = (Date.today-@date_from+1)*zoom + subject_width
          gc.line(x, headers_heigth, x, headers_heigth + g_height-1)      
        end    
        
        gc.draw(imgl)
        imgl.format = format
        imgl.to_blob
      end if Object.const_defined?(:Magick)
      
      private
      
      def gantt_issue_compare(x, y, issues)
        if x.parent_id == y.parent_id
          gantt_start_compare(x, y)
        elsif x.is_ancestor_of?(y)
          -1
        elsif y.is_ancestor_of?(x)
          1
        else
          ax = issues.select {|i| i.is_a?(Issue) && i.is_ancestor_of?(x) && !i.is_ancestor_of?(y) }.sort_by(&:lft).first
          ay = issues.select {|i| i.is_a?(Issue) && i.is_ancestor_of?(y) && !i.is_ancestor_of?(x) }.sort_by(&:lft).first
          if ax.nil? && ay.nil?
            gantt_start_compare(x, y)
          else
            gantt_issue_compare(ax || x, ay || y, issues)
          end
        end
      end
      
      def gantt_start_compare(x, y)
        if x.start_date.nil?
          -1
        elsif y.start_date.nil?
          1
        else
          x.start_date <=> y.start_date
        end
      end

      # TODO: same as the GanttHelper
      def number_of_issues_on_versions
        versions = events.collect {|event| (event.is_a? Version) ? event : nil}.compact

        versions.sum {|v| v.fixed_issues.for_gantt.with_query(query).count}
      end

    end
  end
end
