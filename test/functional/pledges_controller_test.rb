require 'test_helper'

class PledgesControllerTest < ActionController::TestCase
  # Edit

  test "edit" do
    pledge = create :pledge

    get :edit, {id: pledge.id}, session_for(pledge.user)
    assert_response :success

    assert_select 'h1', "Your pledge"
    assert_select 'input[value=5]'
    assert_select 'input[type=submit]'
  end

  test "edit requires login" do
    pledge = create :pledge

    get :edit, {id: pledge.id}
    verify_login_page
  end

  test "edit requires pledge owner" do
    pledge = create :pledge
    user = create :user

    get :edit, {id: pledge.id}, session_for(user)
    verify_wrong_login_page
  end

  # Update

  test "update" do
    pledge = create :pledge

    put :update, {id: pledge.id, pledge: {quantity: 10}}, session_for(pledge.user)
    assert_redirected_to profile_url

    pledge.reload
    assert_equal 10, pledge.quantity
  end

  test "update quantity must be a number" do
    pledge = create :pledge

    put :update, {id: pledge.id, pledge: {quantity: "x"}}, session_for(pledge.user)
    assert_response :success

    assert_select 'h1', "Your pledge"
    assert_select '.field_with_errors', /[a-z]/

    pledge.reload
    assert_equal 5, pledge.quantity
  end

  test "update requires login" do
    pledge = create :pledge

    put :update, {id: pledge.id, pledge: {quantity: 10}}
    verify_login_page
  end

  test "update requires pledge owner" do
    pledge = create :pledge
    user = create :user

    put :update, {id: pledge.id, pledge: {quantity: 10}}, session_for(user)
    verify_wrong_login_page
  end
end
