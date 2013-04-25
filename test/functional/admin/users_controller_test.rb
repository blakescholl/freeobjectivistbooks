require 'test_helper'

class Admin::UsersControllerTest < ActionController::TestCase
  test "index" do
    get :index, params, session_for(users :admin)
    assert_response :success
    assert_select 'h1', "#{User.count} users"
    assert_select '.user', User.count
  end

  test "search" do
    get :index, {q: "h"}, session_for(users :admin)
    assert_response :success
    assert_select '.overview', /matching/
    assert_select '.user'
  end

  test "search with one result" do
    get :index, {q: "roark"}, session_for(users :admin)
    assert_redirected_to [:admin, @howard]
  end

  test "show student" do
    get :show, {id: @howard.id}, session_for(users :admin)
    assert_response :success
    assert_select 'h1', "Howard Roark"
    assert_select '.email', "roark@stanton.edu"
    assert_select '.tagline', "Studying architecture at Stanton Institute of Technology in New York, NY"
    assert_select '.request .headline', "Atlas Shrugged"
    assert_select 'a .edit'
    assert_select 'a .delete'
  end

  test "show donor" do
    get :show, {id: @hugh.id}, session_for(users :admin)
    assert_response :success
    assert_select 'h1', "Hugh Akston"
    assert_select '.email', "akston@patrickhenry.edu"
    assert_select '.tagline', "In Boston, MA"
    assert_select '.request', false
    assert_select '.pledge', /5 books/
    assert_select '.donation', @hugh.donations.count
    assert_select 'a .edit'
    assert_select 'a .delete'
  end

  test "edit" do
    get :edit, {id: @howard.id}, session_for(users :admin)
    assert_response :success
    assert_select 'h1', 'Edit user'
    assert_select 'input[id="user_name"][value="Howard Roark"]'
    assert_select 'input[type="submit"]'
  end

  test "update" do
    put :update, {id: @howard.id, user: {name: "Howard Q. Roark", address: "123 Independence St"}}, session_for(users :admin)
    assert_redirected_to [:admin, @howard]

    @howard.reload
    assert_equal "Howard Q. Roark", @howard.name
    assert_equal "123 Independence St", @howard.address
  end

  test "spoof" do
    post :spoof, {id: @howard.id}, session_for(users :admin)
    assert_redirected_to profile_url
    assert_equal @howard.id, session[:user_id]
  end

  test "destroy" do
    delete :destroy, {id: @howard.id}, session_for(users :admin)
    assert_redirected_to action: :index
    assert !User.exists?(@howard)
  end

  # Security

  test "show requires login" do
    get :show, id: @howard.id
    assert_response :unauthorized
    assert_select '.email', false
    assert_select '.address', false
  end

  test "edit requires login" do
    get :edit, id: @howard.id
    assert_response :unauthorized
    assert_select 'input[id="user_email"]', false
    assert_select 'input[id="user_address"]', false
  end

  test "update requires login" do
    put :update, id: @howard.id, user: {name: "Bogus Name"}
    assert_response :unauthorized

    @howard.reload
    assert_equal "Howard Roark", @howard.name
  end

  test "spoof requires login" do
    post :spoof, id: @howard.id
    assert_response :unauthorized
    assert_nil session[:user_id]
  end

  test "destroy requires login" do
    delete :destroy, id: @howard.id
    assert_response :unauthorized
    assert User.exists?(@howard)
  end
end
