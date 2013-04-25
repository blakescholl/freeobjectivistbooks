require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  test "index" do
    get :index, params, session_for(users :admin)
    assert_response :success
    assert_select 'a', /user/
    assert_select 'a', /request/
    assert_select 'a', /pledge/
    assert_select 'a', /event/
    assert_select 'a', /review/
    assert_select 'a', /testimonial/
    assert_select 'a', /referral/
  end

  test "admin password is required" do
    get :index
    assert_response :unauthorized
  end
end
