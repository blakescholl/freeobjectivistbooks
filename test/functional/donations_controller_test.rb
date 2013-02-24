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
      assert_select '.actions a', /cancel/i
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
    request = create :request
    donor = create :send_books_donor

    post :create, {request_id: request.id, format: "json"}, session_for(donor)
    assert_response :success

    hash = decode_json_response
    assert_equal request.book.title, hash['book']['title']
    assert_equal request.student.name, hash['student']['name']
    assert_equal request.student.location.name, hash['student']['location']['name']

    request.reload
    assert request.granted?
    donation = request.donation
    assert_equal donor, donation.user
    assert donation.donor_mode.send_books?
    assert !donation.flagged?

    verify_event donation, "grant", notified?: true
  end

  test "create send-money" do
    request = create :request
    donor = create :send_money_donor

    post :create, {request_id: request.id, format: "json"}, session_for(donor)
    assert_response :success

    hash = decode_json_response
    assert_equal request.book.title, hash['book']['title']
    assert_equal request.student.name, hash['student']['name']
    assert_equal request.student.location.name, hash['student']['location']['name']

    request.reload
    assert request.granted?
    donation = request.donation
    assert_equal donor, donation.user
    assert donation.donor_mode.send_money?
    assert !donation.flagged?

    verify_event donation, "grant", notified?: true
  end

  test "create no address" do
    request = @howard_request
    post :create, {request_id: request.id, format: "json"}, session_for(@hugh)
    assert_response :success

    hash = decode_json_response
    assert_equal "Atlas Shrugged", hash['book']['title']
    assert_equal "Howard Roark", hash['student']['name']
    assert_equal "New York, NY", hash['student']['location']['name']

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
    assert_select '.flash .error', false
    assert_select 'h1', /cancel/i
    assert_select '.headline', /Quentin Daniels wants to read The Fountainhead/
    assert_select 'h2', /Explain to Quentin Daniels/
    assert_select 'textarea#donation_event_message'
    assert_select 'input[type="submit"]'
  end

  test "cancel already 'sent'" do
    get :cancel, {id: @quentin_donation.id}, session_for(@hugh)
    assert_response :success
    assert_select '.flash .error', /You marked this book as sent/
    assert_select 'h1', /cancel/i
    assert_select '.headline', /Quentin Daniels wants to read The Virtue of Selfishness/
    assert_select 'h2', /Explain to Quentin Daniels/
    assert_select 'textarea#donation_event_message'
    assert_select 'input[type="submit"]'
  end

  test "cancel by student" do
    get :cancel, {id: @quentin_donation_unsent.id, reason: "not_received"}, session_for(@quentin)
    assert_response :success
    assert_select 'h1', /I have not received/i
    assert_select '.overview', /Hugh Akston in Boston, MA donated The Fountainhead/
    assert_select '.overview', /we have not confirmed/i
    assert_select 'input#donation_event_detail[type="hidden"][value="not_received"]'
    assert_select 'input[type="submit"]'
    assert_select 'a', /nevermind/i
    assert_select 'a', /actually, yes/i
  end

  test "cancel requires unreceived donation" do
    get :cancel, {id: @hank_donation_received.id}, session_for(@cameron)
    assert_redirected_to @hank_request_received
    assert_not_nil flash[:error]
  end

  test "cancel requires unpaid donation" do
    get :cancel, {id: @frisco_donation.id}, session_for(@cameron)
    assert_redirected_to @frisco_request
    assert_not_nil flash[:error]
  end

  test "cancel by student requires unsent donation" do
    get :cancel, {id: @quentin_donation.id, reason: "not_received"}, session_for(@quentin)
    assert_redirected_to @quentin_request
    assert_not_nil flash[:error]
  end

  test "cancel requires login" do
    get :cancel, id: @quentin_donation_unsent.id
    verify_login_page
  end

  test "cancel requires donor" do
    get :cancel, {id: @quentin_donation_unsent.id}, session_for(@quentin)
    verify_wrong_login_page
  end

  test "cancel for not-received requires student" do
    get :cancel, {id: @quentin_donation_unsent.id, reason: "not_received"}, session_for(@hugh)
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
    assert_open_at_is_recent @quentin_request_unsent

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

  test "destroy by student" do
    assert_difference "@quentin_donation_unsent.events.count" do
      delete :destroy, {id: @quentin_donation_unsent.id, donation: {event: {detail: "not_received"}}}, session_for(@quentin)
    end

    assert_redirected_to @quentin_request_unsent
    assert_match /put you back at the top/i, flash[:notice]

    @quentin_donation_unsent.reload
    assert @quentin_donation_unsent.canceled?, "donation is not canceled"

    @quentin_request_unsent.reload
    assert @quentin_request_unsent.open?, "request is not open"
    assert_open_at_is_recent @quentin_request_unsent

    verify_event @quentin_donation_unsent, "cancel_donation", detail: "not_received", notified?: true
  end

  test "destroy requires unreceived donation" do
    assert_no_difference "@hank_donation_received.events.count" do
      delete :destroy, {id: @hank_donation_received.id, donation: {event: {message: "Sorry!"}}}, session_for(@cameron)
    end
    assert_redirected_to @hank_request_received
    assert_not_nil flash[:error]

    @hank_donation_received.reload
    assert !@hank_donation_received.canceled?, "donation was canceled"
  end

  test "destroy requires unpaid donation" do
    assert_no_difference "@frisco_donation.events.count" do
      delete :destroy, {id: @frisco_donation.id, donation: {event: {message: "Sorry!"}}}, session_for(@cameron)
    end
    assert_redirected_to @frisco_request
    assert_not_nil flash[:error]

    @frisco_donation.reload
    assert !@frisco_donation.canceled?, "donation was canceled"
  end

  test "destroy by student requires unsent donation" do
    assert_no_difference "@quentin_donation.events.count" do
      delete :destroy, {id: @quentin_donation.id, donation: {event: {detail: "not_received"}}}, session_for(@quentin)
    end
    assert_redirected_to @quentin_request
    assert_not_nil flash[:error]

    @quentin_donation.reload
    assert !@quentin_donation.canceled?, "donation was canceled"
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
