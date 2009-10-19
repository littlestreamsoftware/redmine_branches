# redMine - project management software
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

require File.dirname(__FILE__) + '/../../../../test_helper'

class Redmine::Helpers::GanttTest < ActiveSupport::TestCase

  context "#number_of_rows" do

    context "with one project" do
      should "return the number of rows just for that project"
    end

    context "with no project" do
      should "return the total number of rows for all the projects, resursively"
    end

  end

  context "#number_of_rows_on_project" do
    should "clear the @query.project so cross-project issues and versions can be counted"
    should "count 1 for the project itself"
    should "count the number of issues without a version"
    should "count the number of versions"
    should "count the number of issues on versions, including cross-project"
    should "recursive and count the number of rows on each subproject"
  end

  context "#tasks_subjects" do
    should "be tested"
  end

  context "#tasks_subjects_for_project" do
    should "be tested"
  end

  context "#tasks_subjects_for_issues" do
    should "be tested"
  end

  context "#tasks_subjects_for_version" do
    should "be tested"
  end

  context "#tasks" do
    should "be tested"
  end

  context "#subject_for_project" do
    should "be tested"
  end

  context "#line_for_project" do
    should "be tested"
  end

  context "#subject_for_version" do
    should "be tested"
  end

  context "#line_for_version" do
    should "be tested"
  end

  context "#subject_for_issue" do
    should "be tested"
  end

  context "#line_for_issue" do
    should "be tested"
  end

  context "#to_image" do
    should "be tested"
  end

  context "#to_pdf" do
    should "be tested"
  end
  
end
