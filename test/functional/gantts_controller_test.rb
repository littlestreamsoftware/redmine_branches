require 'test_helper'

class GanttsControllerTest < ActionController::TestCase
  fixtures :all

  context "#gantt" do
    should "work" do
      i2 = Issue.find(2)
      i2.update_attribute(:due_date, 1.month.from_now)
      
      get :show, :project_id => 1
      assert_response :success
      assert_template 'show.html.erb'
      assert_not_nil assigns(:gantt)
      events = assigns(:gantt).events
      assert_not_nil events
      # Issue with start and due dates
      i = Issue.find(1)
      assert_not_nil i.due_date
      assert events.include?(Issue.find(1))
      # Issue with on a targeted version should not be in the events but loaded in the html
      i = Issue.find(2)
      assert !events.include?(i)
      assert_select "div a.issue", /##{i.id}/
    end

    should "work cross project" do
      get :show
      assert_response :success
      assert_template 'show.html.erb'
      assert_not_nil assigns(:gantt)
      events = assigns(:gantt).events
      assert_not_nil events
    end

    should "export to pdf" do
      get :show, :project_id => 1, :format => 'pdf'
      assert_response :success
      assert_equal 'application/pdf', @response.content_type
      assert @response.body.starts_with?('%PDF')
      assert_not_nil assigns(:gantt)
    end

    should "export to pdf cross project" do
      get :show, :format => 'pdf'
      assert_response :success
      assert_equal 'application/pdf', @response.content_type
      assert @response.body.starts_with?('%PDF')
      assert_not_nil assigns(:gantt)
    end
    
    should "export to png" do
      get :show, :project_id => 1, :format => 'png'
      assert_response :success
      assert_equal 'image/png', @response.content_type
    end if Object.const_defined?(:Magick)

  end
end
