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
    assert_select 'a', /cancel/i
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

    verify_event pledge, "update"
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

  # Cancel

  test "cancel" do
    pledge = create :pledge

    get :cancel, {id: pledge.id}, session_for(pledge.user)
    assert_response :success

    assert_select 'h1', "Cancel your pledge"
    assert_select 'textarea'
    assert_select 'input[type=submit]'
    assert_select 'a', /don.+t cancel/i
  end

  test "cancel requires login" do
    pledge = create :pledge

    get :cancel, {id: pledge.id}
    verify_login_page
  end

  test "cancel requires pledge owner" do
    pledge = create :pledge
    user = create :user

    get :cancel, {id: pledge.id}, session_for(user)
    verify_wrong_login_page
  end

  # Delete

  def delete_params(pledge, message = "")
    {id: pledge.id, pledge: {event: {message: message}}}
  end

  test "delete" do
    pledge = create :pledge

    delete :destroy, delete_params(pledge), session_for(pledge.user)
    assert_redirected_to profile_url
    assert_not_nil flash[:notice]

    pledge.reload
    assert pledge.canceled?

    verify_event pledge, "cancel_pledge"
  end

  test "delete with message" do
    pledge = create :pledge

    delete :destroy, delete_params(pledge, "Don't want to"), session_for(pledge.user)
    assert_redirected_to profile_url
    assert_not_nil flash[:notice]

    pledge.reload
    assert pledge.canceled?

    verify_event pledge, "cancel_pledge", message: "Don't want to"
  end

  test "delete requires login" do
    pledge = create :pledge

    delete :destroy, delete_params(pledge)
    verify_login_page

    pledge.reload
    assert pledge.active?
  end

  test "delete requires pledge owner" do
    pledge = create :pledge
    user = create :user

    delete :destroy, delete_params(pledge), session_for(user)
    verify_wrong_login_page

    pledge.reload
    assert pledge.active?
  end
end
