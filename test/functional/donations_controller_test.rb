require 'test_helper'

class DonationsControllerTest < ActionController::TestCase
  # Index

  test "index" do
    get :index, params, session_for(@hugh)
    assert_response :success
    assert_select 'h1', "Your donations"

    assert_select '.donation', /Virtue of Selfishness to/ do
      assert_select '.request .name', /Quentin Daniels/
      assert_select '.request .address', /123 Main St/
      assert_select '.actions a', /see full/i
      assert_select '.actions a', text: /cancel/i, count: 0
      assert_select '.actions a', text: /flag/i, count: 0
    end

    assert_select '.donation', /Capitalism: The Unknown Ideal to/ do
      assert_select '.request .name', /Dagny/
      assert_select '.request .address', /No address/
      assert_select '.actions a', /see full/i
      assert_select '.actions a', text: /flag/i, count: 0
      assert_select '.actions a', /cancel/i
      assert_select '.actions .flagged', /Student has been contacted/i
    end

    assert_select '.donation', /The Fountainhead to/ do
      assert_select '.request .name', /Quentin Daniels/
      assert_select '.request .address', /123 Main St/
      assert_select '.actions form'
      assert_select '.actions a', /see full/i
      assert_select '.actions a', /flag/i
      assert_select '.actions a', /cancel/i
      assert_select '.actions .flagged', false
    end
  end

  test "index with flagged shipping info" do
    get :index, params, session_for(@cameron)
    assert_response :success
    assert_select 'h1', "Your donations"

    assert_select '.donation', /Atlas Shrugged to/ do
      assert_select '.request .name', /Hank Rearden/
      assert_select '.request .address', /987 Steel Way/
      assert_select '.actions a', /see full/i
      assert_select '.actions a', text: /flag/i, count: 0
      assert_select '.actions .flagged', /Shipping info flagged/i
      assert_select '.actions a', /cancel/i
    end
  end

  test "index requires login" do
    get :index
    verify_login_page
  end

  # Create

  test "create" do
    request = @quentin_request_open
    post :create, {request_id: request.id, format: "json"}, session_for(@hugh)
    assert_response :success

    hash = decode_json_response
    assert_equal "Objectivism: The Philosophy of Ayn Rand", hash['book']
    assert_equal "Quentin Daniels", hash['user']['name']

    request.reload
    assert request.granted?
    donation = request.donation
    assert_equal @hugh, donation.user
    assert !donation.flagged?

    verify_event donation, "grant", notified?: true
  end

  test "create no address" do
    request = @howard_request
    post :create, {request_id: request.id, format: "json"}, session_for(@hugh)
    assert_response :success

    hash = decode_json_response
    assert_equal "Atlas Shrugged", hash['book']
    assert_equal "Howard Roark", hash['user']['name']

    request.reload
    assert request.granted?
    donation = request.donation
    assert_equal @hugh, donation.user
    assert donation.flagged?

    verify_event donation, "grant", notified?: true
  end

  test "create is idempotent" do
    request = @quentin_request
    post :create, {request_id: request.id, format: "json"}, session_for(@hugh)
    assert_response :success

    request.reload
    assert_equal @quentin_donation, request.donation
  end

  test "can't grant request that is already granted" do
    request = @quentin_request
    post :create, {request_id: request.id, format: "json"}, session_for(@cameron)
    assert_response :bad_request

    hash = decode_json_response
    assert_match /already/i, hash['message']

    request.reload
    assert_equal @hugh, request.donor
  end

  test "can't donate to self" do
    request = @quentin_request
    post :create, {request_id: request.id, format: "json"}, session_for(@quentin)
    assert_response :bad_request

    hash = decode_json_response
    assert_match /yourself/i, hash['message']

    request.reload
    assert_equal @hugh, request.donor
  end

  test "create requires login" do
    post :create, request_id: @howard_request.id, format: "json"
    assert_response :unauthorized
  end

  # Cancel

  test "cancel" do
    get :cancel, {id: @quentin_donation_unsent.id}, session_for(@hugh)
    assert_response :success
    assert_select 'h1', /cancel/i
    assert_select '.headline', /Quentin Daniels in Boston, MA wants to read The Fountainhead/
    assert_select 'h2', /Explain to Quentin Daniels/
    assert_select 'textarea#donation_event_message'
    assert_select 'input[type="submit"]'
  end

  test "cancel requires login" do
    get :cancel, id: @quentin_donation_unsent.id
    verify_login_page
  end

  test "cancel requires donor" do
    get :cancel, {id: @quentin_donation_unsent.id}, session_for(@howard)
    verify_wrong_login_page
  end

  # Destroy

  test "destroy" do
    assert_difference "@quentin_donation_unsent.events.count" do
      delete :destroy, {id: @quentin_donation_unsent.id, donation: {event: {message: "Sorry!"}}}, session_for(@hugh)
    end

    assert_redirected_to donations_url
    assert_match /We let Quentin Daniels know/i, flash[:notice][:headline]

    @quentin_donation_unsent.reload
    assert @quentin_donation_unsent.canceled?, "donation is not canceled"

    @quentin_request_unsent.reload
    assert @quentin_request_unsent.open?, "request is not open"

    verify_event @quentin_donation_unsent, "cancel_donation", message: "Sorry!", notified?: true
  end

  test "destroy requires message" do
    assert_no_difference "@quentin_donation_unsent.events.count" do
      delete :destroy, {id: @quentin_donation_unsent.id, donation: {event: {message: ""}}}, session_for(@hugh)
    end

    assert_response :success
    assert_select 'h1', /cancel/i

    @quentin_donation_unsent.reload
    assert @quentin_donation_unsent.active?

    @quentin_request_unsent.reload
    assert @quentin_request_unsent.granted?
  end

  test "destroy requires login" do
    delete :destroy, {id: @quentin_donation_unsent.id, donation: {event: {message: "Sorry!"}}}
    verify_login_page
  end

  test "destroy requires donor" do
    delete :destroy, {id: @quentin_donation_unsent.id, donation: {event: {message: "Sorry!"}}}, session_for(@howard)
    verify_wrong_login_page
  end
end
