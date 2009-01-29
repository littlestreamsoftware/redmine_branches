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

require File.dirname(__FILE__) + '/../../test_helper'

class StaleObjectTest < Test::Unit::TestCase

  # TODO: context
  # initialize
  def test_attributes_set
    issue = Issue.find(:first)
    stale = StaleObject.new(issue)
    assert stale.attributes == issue.attributes
  end

  def test_invalid_stale_object_should_raise_an_exception
    object = Object.new
    assert_raise ArgumentError do
      stale = StaleObject.new(object)
    end
  end
  
  # difference_messages
  def test_difference_message_with_no_changes_should_be_an_empty_string
    issue = Issue.find(:first)
    stale = StaleObject.new(issue)
    assert stale.difference_messages(issue).empty?
  end

  def test_difference_message_with_changes_on_fields_should_return_the_field_names_and_values
    issue = Issue.find(:first)
    stale = StaleObject.new(issue)
    issue.subject = "Changed"
    
    message = stale.difference_messages(issue)
    assert_match /subject/i, message
    assert_match /changed/i, message
  end

  def test_difference_message_with_changes_on_associations_should_return_the_association_names
    issue = Issue.find(:first)
    stale = StaleObject.new(issue)
    issue.status = IssueStatus.find(6)
    
    message = stale.difference_messages(issue)
    assert_match /status/i, message
    assert_match /new/i, message
  end
  
  def test_difference_message_with_changes_on_associations_should_work_with_nils
    issue = Issue.find(:first)
    issue.category = IssueCategory.find(:last)
    stale = StaleObject.new(issue)
    issue.category = nil # Set association to nil
    
    message = stale.difference_messages(issue)
    assert_match /category/i, message
    assert_match /printing/i, message
  end

  def test_difference_message_with_nil_set_on_a_field_should_show_none
    issue = Issue.find(:first)
    issue.estimated_hours = 6
    stale = StaleObject.new(issue)
    issue.estimated_hours = nil
    
    message = stale.difference_messages(issue)
    assert_match /est/i, message
    assert_match /6/i, message
  end

  def test_difference_message_should_allow_for_a_different_wrap_tag
    issue = Issue.find(:first)
    stale = StaleObject.new(issue)
    issue.subject = "Changed"
    
    message = stale.difference_messages(issue, :wrap => "span")
    assert_match /<span>/i, message
    assert_match /<\/span>/i, message
  end

  def test_difference_message_should_allow_for_a_different_item_tag
    issue = Issue.find(:first)
    stale = StaleObject.new(issue)
    issue.subject = "Changed"
    
    message = stale.difference_messages(issue, :item => "span")
    assert_match /<span>/i, message
    assert_match /<\/span>/i, message
  end
end

