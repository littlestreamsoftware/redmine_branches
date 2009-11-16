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
  # Utility methods and classes so assert_select can be used.
  class GanttViewTest < ActionView::Base
    include ApplicationHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TextHelper
    include ActionController::UrlWriter

    def self.default_url_options
      {:only_path => true }
    end

  end

  include ActionController::Assertions::SelectorAssertions

  def setup
    @response = ActionController::TestResponse.new
  end

  def build_view
    @view = GanttViewTest.new
  end

  def html_document
    HTML::Document.new(@response.body)
  end

  context "#number_of_rows" do

    context "with one project" do
      should "return the number of rows just for that project"
    end

    context "with no project" do
      should "return the total number of rows for all the projects, resursively"
    end

  end

  context "#number_of_rows_on_project" do
    setup do
      # Fixtures
      ProjectCustomField.delete_all
      Project.destroy_all
      
      @project = Project.generate!
      @gantt = Redmine::Helpers::Gantt.new
      @gantt.project = @project
      @gantt.query = Query.generate_default!(:project => @project)
    end
    
    should "clear the @query.project so cross-project issues and versions can be counted" do
      assert @gantt.query.project
      @gantt.number_of_rows_on_project(@project)
      assert_nil @gantt.query.project
    end

    should "count 1 for the project itself" do
      assert_equal 1, @gantt.number_of_rows_on_project(@project)
    end

    should "count the number of issues without a version" do
      @project.issues << Issue.generate_for_project!(@project, :fixed_version => nil)
      assert_equal 2, @gantt.number_of_rows_on_project(@project)
    end

    should "count the number of versions" do
      @project.versions << Version.generate!
      @project.versions << Version.generate!
      assert_equal 3, @gantt.number_of_rows_on_project(@project)
    end

    should "count the number of issues on versions, including cross-project" do
      version = Version.generate!
      @project.versions << version
      @project.issues << Issue.generate_for_project!(@project, :fixed_version => version)
      
      assert_equal 3, @gantt.number_of_rows_on_project(@project)
    end
    
    should "recursive and count the number of rows on each subproject" do
      @project.versions << Version.generate! # +1

      @subproject = Project.generate!(:enabled_module_names => ['issue_tracking']) # +1
      @subproject.set_parent!(@project)
      @subproject.issues << Issue.generate_for_project!(@subproject) # +1
      @subproject.issues << Issue.generate_for_project!(@subproject) # +1

      @subsubproject = Project.generate!(:enabled_module_names => ['issue_tracking']) # +1
      @subsubproject.set_parent!(@subproject)
      @subsubproject.issues << Issue.generate_for_project!(@subsubproject) # +1

      assert_equal 7, @gantt.number_of_rows_on_project(@project) # +1 for self
    end
  end

  context "#subjects" do
    should "be tested"
  end

  context "#lines" do
    should "be tested"
  end

  context "#render_project" do
    should "be tested"
  end

  context "#render_issues" do
    should "be tested"
  end

  context "#render_version" do
    should "be tested"
  end

  context "#subject_for_project" do
    setup do
      # Fixtures
      ProjectCustomField.delete_all
      Project.destroy_all
      
      @project = Project.generate!
      @gantt = Redmine::Helpers::Gantt.new
      @gantt.project = @project
      @gantt.query = Query.generate_default!(:project => @project)
      @gantt.view = build_view
    end
    
    context ":html format" do
      should "add an absolute positioned div" do
        @response.body = @gantt.subject_for_project(@project, {:format => :html})
        assert_select "div[style*=absolute]"
      end

      should "use the indent option to move the div to the right" do
        @response.body = @gantt.subject_for_project(@project, {:format => :html, :indent => 40})
        assert_select "div[style*=left:40]"
      end

      should "include the project name" do
        @response.body = @gantt.subject_for_project(@project, {:format => :html})
        assert_select 'div', :text => /#{@project.name}/
      end

      should "include a link to the project" do
        @response.body = @gantt.subject_for_project(@project, {:format => :html})
        assert_select 'a[href=?]', Regexp.escape("/projects/#{@project.identifier}"), :text => /#{@project.name}/
      end

      should "style overdue projects" do
        @project.enabled_module_names = [:issue_tracking]
        @project.versions << Version.generate!(:effective_date => Date.yesterday)

        assert @project.overdue?, "Need an overdue project for this test"
        @response.body = @gantt.subject_for_project(@project, {:format => :html})

        assert_select 'div span.project-overdue'
      end


    end

    should "test the PNG format"
    should "test the PDF format"
  end

  context "#line_for_project" do
    context ":html format" do
      context "todo line" do
        should "start from the starting point on the left"
        should "be the total width of the issue"
      end
    end
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
