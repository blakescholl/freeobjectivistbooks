require 'test_helper'

class DonationsControllerTest < ActionController::TestCase
  # Index

  test "index" do
    user = create :donor
    sent_donation = create :donation, :sent, user: user
    paid_donation = create :donation, :paid, user: user
    flagged_donation = create :donation_for_request_no_address, user: user

    fulfilled_donation = create :donation, :paid, user: user
    create :fulfillment, donation: fulfilled_donation

    sent_fulfilled_donation = create :donation, :paid, :sent, user: user
    create :fulfillment, donation: sent_fulfilled_donation

    get :index, params, session_for(user)
    assert_response :success
    assert_select 'h1', "Your donations"

    assert_select '.donation', 5 do
      assert_select '.headline a'
    end

    assert_select '.donation', /#{sent_donation.book} to #{sent_donation.student}/ do
      assert_select '.status', /Book sent/
    end

    assert_select '.donation', /#{paid_donation.book} to #{paid_donation.student}/ do
      assert_select '.status', /Paid/
    end

    assert_select '.donation', /#{flagged_donation.book} to #{flagged_donation.student}/ do
      assert_select '.flagged'
    end

    assert_select '.donation', /#{fulfilled_donation.book} to #{fulfilled_donation.student}/ do
      assert_select '.status', /Paid/
    end

    assert_select '.donation', /#{sent_fulfilled_donation.book} to #{sent_fulfilled_donation.student}/ do
      assert_select '.status', /Book sent/
    end

    assert_select '.error', false
    assert_select 'a', text: /Find students/, count: 0
  end

  test "index with no donations" do
    user = create :donor

    get :index, params, session_for(user)
    assert_response :success

    assert_select 'h1', "Your donations"
    assert_select 'p', /None yet/
    assert_select 'a', /Find students/
  end

  test "index with outstanding donations" do
    user = create :donor
    create :donation, user: user
    create :donation_for_request_not_amazon, user: user

    get :index, params, session_for(user)
    assert_response :success

    assert_select 'h1', "Your donations"

    assert_select '.message.error' do
      assert_select '.headline', /unsent donations/
      assert_select 'a', /send/
    end

    assert_select '.donation', 2 do
      assert_select '.status', /Not sent/
    end

    assert_select 'a', text: /Find students/, count: 0
  end

  test "index requires login" do
    get :index
    verify_login_page
  end

  # Outstanding

  test "outstanding" do
    user = create :donor
    donation = create :donation, user: user
    ineligible_donation = create :donation_for_request_not_amazon, user: user
    create :donation_for_request_no_address, user: user
    create :donation, :sent, user: user
    create :donation, :paid, user: user

    get :outstanding, params, session_for(user)
    assert_response :success

    assert_select 'h1', /Outstanding/

    assert_select '.donation', 2 do
      assert_select '.headline a'
      assert_select '.button.donation-send'
      assert_select '.shipping'
    end

    assert_select '.donation', /#{donation.book} to #{donation.student}/ do
      assert_select '.buttons' do
        assert_select '.button.donation-pay'
        assert_select '.book_price', "$10"
        assert_select '.checkmark'
      end

      assert_select '.shipping' do
        assert_select '.request' do
          assert_select '.name', donation.student.name
          assert_select '.address', /\d+ Main St/
        end
        assert_select '.actions' do
          assert_select 'form'
          assert_select 'a', 3
          assert_select 'a', /Amazon/
          assert_select 'a', /Flag/
          assert_select 'a', /Close/
        end
      end
    end

    assert_select '.donation', /#{ineligible_donation.book} to #{ineligible_donation.student}/ do
      assert_select '.buttons' do
        assert_select '.button.donation-pay', false
        assert_select '.book_price', false
        assert_select '.checkmark', false
      end

      assert_select '.shipping' do
        assert_select '.request' do
          assert_select '.name', ineligible_donation.student.name
          assert_select '.address', /\d+ Main St/
        end
        assert_select '.actions' do
          assert_select 'form'
          assert_select 'a', 2
          assert_select 'a', text: /Amazon/, count: 0
          assert_select 'a', /Flag/
          assert_select 'a', /Close/
        end
      end
    end

    assert_select '#payment-button-row'
  end

  test "outstanding page with nothing outstanding" do
    user = create :donor
    create :donation, :sent, user: user
    create :donation, :paid, user: user

    get :outstanding, params, session_for(user)
    assert_response :success

    assert_select 'h1', /Outstanding/
    assert_select '.donation', false
  end

  test "outstanding page with flagged donation" do
    user = create :donor
    create :donation_for_request_no_address, user: user

    get :outstanding, params, session_for(user)
    assert_response :success

    assert_select 'h1', /Outstanding/
    assert_select '.donation', false
    assert_select '.flagged', /1 donation flagged/
  end

  test "outstanding page requires login" do
    get :outstanding
    verify_login_page
  end

  # Create

  test "create" do
    request = create :request
    donor = create :donor

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
    assert !donation.paid?
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
