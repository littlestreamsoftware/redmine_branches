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
end
