require 'test_helper'

class Admin::ReviewsControllerTest < ActionController::TestCase
  # Index

  test "index" do
    get :index, params, session_for(users :admin)
    assert_response :success
    assert_select 'h1', "Reviews"
    assert_select '.review', Review.count
  end

  test "index requires login" do
    get :index
    assert_response :unauthorized
    assert_select '.review', 0
  end
end
