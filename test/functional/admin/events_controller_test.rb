require 'test_helper'

class Admin::EventsControllerTest < ActionController::TestCase
  test "index" do
    authenticate_with_http_digest "admin", "password", "Admin"
    get :index
    assert_response :success
    assert_select 'h1', /#{Event.count} event/
    assert_select '.event', Event.count
  end

  test "show requires login" do
    get :index
    assert_response :unauthorized
    assert_select '.event', 0
  end
end