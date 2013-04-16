require 'test_helper'

class Admin::RequestsControllerTest < ActionController::TestCase
  # Index

  test "index" do
    admin_auth
    get :index
    assert_response :success
    assert_select 'h1', "Requests"
    assert_select '.overview table'
    assert_select '.request', Request.count
  end

  test "index requires login" do
    get :index
    assert_response :unauthorized
    assert_select '.request', 0
  end

  # Show

  test "show no donor" do
    admin_auth
    get :show, id: @howard_request.id
    assert_response :success
    assert_select 'h1', /Howard Roark wants\s+Atlas Shrugged/
    assert_select 'h2', /looking for donor/i
  end

  test "show with donor" do
    admin_auth
    get :show, id: @hank_request.id
    assert_response :success
    assert_select 'h1', /Hank Rearden wants\s+Atlas Shrugged/
    assert_select 'h2', /donor found/i
  end

  test "show with book sent" do
    admin_auth
    get :show, id: @quentin_request.id
    assert_response :success
    assert_select 'h1', /Quentin Daniels wants\s+The Virtue of Selfishness/
    assert_select 'h2', /book sent/i
  end

  test "show with fulfiller" do
    fulfillment = create :fulfillment

    admin_auth
    get :show, id: fulfillment.request.id
    assert_response :success
    assert_select 'h1', /Student \d+ wants\s+Book \d+/
    assert_select 'h2', /donor found/i
  end

  test "show requires login" do
    get :show, id: @howard_request.id
    assert_response :unauthorized
  end
end
