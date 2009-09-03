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
    headers_height = options.delete(:headers_height)
    events = options.delete(:events)
    
    output = ''
    top = headers_height + 8
    events.each do |i|
      left = 4 + (i.is_a?(Issue) ? i.level * 16 : 0)

      output << "<div style='position: absolute;line-height:1.2em;height:16px;top:#{top}px;left:#{left}px;overflow:hidden;'><small>    "
      if i.is_a? Issue
        output << h("#{i.project} -") unless @project && @project == i.project
        output << link_to_issue(i)
      else
        output << '<span class="icon icon-package">'
        output << link_to_version(i)
        output << "</span>"
      end
      output << "</small></div>"
      top = top + 20
    end
    output
  end
end
