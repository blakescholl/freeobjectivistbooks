require 'test_helper'

class FulfillmentsControllerTest < ActionController::TestCase
  # Volunteers index

  test "volunteer" do
    user = create :volunteer
    donation = create :donation_with_send_money_donor, paid: true

    get :volunteer, params, session_for(user)
    assert_response :success

    assert_select 'h2', text: /Claimed/, count: 0

    assert_select '.fulfillment', /#{donation.book}/ do
      assert_select '.donation', /#{donation.book} to #{donation.student}/
      assert_select '.donation', /On behalf of #{donation.donor}/
      assert_select '.actions form'
    end
  end

  test "volunteers index with unsent fulfillments" do
    user = create :volunteer
    fulfillment = create :fulfillment, user: user
    donation = create :donation_with_send_money_donor, paid: true

    get :volunteer, params, session_for(user)
    assert_response :success

    assert_select 'h2', /Claimed/

    assert_select '.fulfillment', /#{fulfillment.book}/ do
      assert_select '.donation', /#{fulfillment.book} to #{fulfillment.student}/
      assert_select '.donation', /On behalf of #{fulfillment.donor}/
      assert_select '.actions a'
    end

    assert_select '.fulfillment', /#{donation.book}/ do
      assert_select '.donation', /#{donation.book} to #{donation.student}/
      assert_select '.donation', /On behalf of #{donation.donor}/
      assert_select '.actions form'
    end
  end

  test "volunteers index requires login" do
    get :volunteer
    verify_login_page
  end

  test "volunteers index requires volunteer" do
    get :volunteer, params, session_for(@howard)
    verify_wrong_login_page
  end

  # Create

  test "create" do
    post :create, {donation_id: @frisco_donation.id}, session_for(@kira)
    @frisco_donation.reload
    fulfillment = @frisco_donation.fulfillment

    assert_not_nil fulfillment
    assert_redirected_to fulfillment
    assert_equal @kira, fulfillment.user
  end

  test "create is idempotent" do
    post :create, {donation_id: @frisco_donation.id}, session_for(@kira)
    @frisco_donation.reload
    fulfillment = @frisco_donation.fulfillment

    post :create, {donation_id: @frisco_donation.id}, session_for(@kira)
    assert_redirected_to fulfillment

    @frisco_donation.reload
    assert_equal fulfillment, @frisco_donation.fulfillment
  end

  test "create fails if donation already fulfilled" do
    @frisco_donation.fulfill @kira

    post :create, {donation_id: @frisco_donation.id}, session_for(@irina)
    assert_redirected_to volunteer_url
    assert_match /already/i, flash[:error]

    @frisco_donation.reload
    assert_equal @kira, @frisco_donation.fulfillment.user
  end

  test "create requires login" do
    post :create, {donation_id: @frisco_donation.id}
    verify_login_page
  end

  test "create requires volunteer" do
    post :create, {donation_id: @frisco_donation.id}, session_for(@howard)
    verify_wrong_login_page
  end

  # Show

  test "show" do
    fulfillment = @frisco_donation.fulfill @kira
    get :show, {id: fulfillment.id}, session_for(@kira)
    assert_response :success
    assert_select 'a', text: @frisco_donation.book.amazon_url
  end

  test "show requires login" do
    fulfillment = @frisco_donation.fulfill @kira
    get :show, {id: fulfillment.id}
    verify_login_page
  end

  test "show requires fulfiller" do
    fulfillment = @frisco_donation.fulfill @kira
    get :show, {id: fulfillment.id}, session_for(@irina)
    verify_wrong_login_page
  end
end
