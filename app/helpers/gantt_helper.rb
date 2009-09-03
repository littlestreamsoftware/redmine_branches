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
  def tasks_subjects(options={})
    events = options.delete(:events)
    top = options.delete(:top)
    indent = options.delete(:indent) || 4
    
    output = ''
    events.each do |i|
      output << "<div style='position: absolute;line-height:1.2em;height:16px;top:#{top}px;left:#{indent}px;overflow:hidden;'><small>    "
      if i.is_a? Issue
      	output << h("#{i.project} -") unless @project && @project == i.project
      	output << link_to_issue(i)
        output << ":"
        output << h(i.subject)
      elsif i.is_a? Version
        output << '<span class="icon icon-package">'
        output << h("#{i.project} -") unless @project && @project == i.project
        output << link_to_version(i)
      else
        # Nothing
      end
      output << "</small></div>"
      top = top + 20
      if i.is_a? Version
        issues = i.fixed_issues.for_gantt.with_query(@query)
        if issues
          output << tasks_subjects(:top => top, :events => issues, :indent => indent + 30)
          top = top + (20 * issues.length) # Pad the top for each issue displayed
        end
      end
    end
    output
  end

  def tasks(options)
    top = options.delete(:top)
    zoom = options.delete(:zoom)
    
    output = ''
    @gantt.events.each do |i| 
      if i.is_a? Issue 
        i_start_date = (i.start_date >= @gantt.date_from ? i.start_date : @gantt.date_from )
        i_end_date = (i.due_before <= @gantt.date_to ? i.due_before : @gantt.date_to )
	
        i_done_date = i.start_date + ((i.due_before - i.start_date+1)*i.done_ratio/100).floor
        i_done_date = (i_done_date <= @gantt.date_from ? @gantt.date_from : i_done_date )
        i_done_date = (i_done_date >= @gantt.date_to ? @gantt.date_to : i_done_date )
	
        i_late_date = [i_end_date, Date.today].min if i_start_date < Date.today
	
        i_left = ((i_start_date - @gantt.date_from)*zoom).floor 	
        i_width = ((i_end_date - i_start_date + 1)*zoom).floor - 2                  # total width of the issue (- 2 for left and right borders)
        d_width = ((i_done_date - i_start_date)*zoom).floor - 2                     # done width
        l_width = i_late_date ? ((i_late_date - i_start_date+1)*zoom).floor - 2 : 0 # delay width
        css = "task " + (i.leaf? ? 'leaf' : 'parent')
	
        output << "<div style='top:#{ top }px;left:#{ i_left }px;width:#{ i_width }px;' class='#{css} task task_todo'>&nbsp;</div>"
        if l_width > 0
          output << "<div style='top:#{ top }px;left:#{ i_left }px;width:#{ l_width }px;' class='#{css} task task_late'>&nbsp;</div>"
        end
        if d_width > 0
          output<< "<div style='top:#{ top }px;left:#{ i_left }px;width:#{ d_width }px;' class='#{css} task task_done'>&nbsp;</div>"
        end
        output << "<div style='top:#{ top }px;left:#{ i_left + i_width + 5 }px;background:#fff;' class='#{css} task'>"
        output << i.status.name
        output << (i.done_ratio).to_i
        output << "%"
        output << "</div>"

        output << "<div class='tooltip' style='position: absolute;top:#{ top }px;left:#{ i_left }px;width:#{ i_width }px;height:12px;'>"
        output << '<span class="tip">'
        output << render_issue_tooltip(i)
        output << "</span></div>"
      else 
        i_left = ((i.start_date - @gantt.date_from)*zoom).floor

        output << "<div style='top:#{ top }px;left:#{ i_left }px;width:15px;' class='task milestone'>&nbsp;</div>"
        output << "<div style='top:#{ top }px;left:#{ i_left + 12 }px;background:#fff;' class='task'>"
		output << h("#{i.project} -") unless @project && @project == i.project
		output << "<strong>#{h i }</strong>"
        output << "</div>"
      end
      top = top + 20
    end
    output
  end
end
