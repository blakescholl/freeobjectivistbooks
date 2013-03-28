require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test "index is home if not logged in" do
    get :index
    assert_response :success
    assert_select 'h1', "Free Objectivist Books for Students"
  end

  test "index redirects to profile if logged in" do
    get :index, params, session_for(@howard)
    assert_redirected_to profile_url
  end

  test "home" do
    get :home, params, session_for(@howard)
    assert_response :success
    assert_select 'h1', "Free Objectivist Books for Students"
  end

  test "about" do
    get :about
    assert_response :success
    assert_select 'h1', /About/
  end

  test "terms" do
    get :terms
    assert_response :success
    assert_select 'h1', /Terms of service/
  end

  test "privacy" do
    get :privacy
    assert_response :success
    assert_select 'h1', /Privacy policy/
  end
end
