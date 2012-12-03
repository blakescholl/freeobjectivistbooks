require 'test_helper'

class StatusesControllerTest < ActionController::TestCase
  # Sent "form"

  test "received form redirects to request" do
    get :edit, {donation_id: @dagny_donation.id, status: "sent"}, session_for(@hugh)
    assert_redirected_to @dagny_request
  end

  # Sent

  test "sent" do
    assert_difference "@dagny_donation.events.count" do
      put :update, {donation_id: @dagny_donation.id, donation: {status: "sent"}}, session_for(@hugh)
    end
    assert_redirected_to @dagny_request
    assert_match /We've let Dagny know/, flash[:notice]

    @dagny_donation.reload
    assert @dagny_donation.status.sent?, @dagny_donation.status.to_s

    verify_event @dagny_donation, "update_status", detail: "sent"
  end

  test "sent requires login" do
    put :update, {donation_id: @dagny_donation.id, donation: {status: "sent"}}
    verify_login_page
  end

  test "sent requires donor" do
    put :update, {donation_id: @dagny_donation.id, donation: {status: "sent"}}, session_for(@dagny)
    verify_wrong_login_page
  end

  # Received form

  test "received form" do
    get :edit, {donation_id: @quentin_donation.id, status: "received"}, session_for(@quentin)
    assert_response :success
    assert_select 'p', /Hugh Akston in Boston, MA donated The Virtue of Selfishness/
    assert_select 'h2', /Add a thank-you message for Hugh Akston/
    assert_select 'input#donation_event_is_thanks[type="hidden"][value=true]'
    assert_select 'textarea#donation_event_message'
    assert_select 'input[type="radio"]'
    assert_select 'input[type="submit"]'
  end

  test "received form for an unsent donation" do
    get :edit, {donation_id: @quentin_donation_unsent.id, status: "received"}, session_for(@quentin)
    assert_response :success
    assert_select 'p', /Hugh Akston in Boston, MA donated The Fountainhead/
    assert_select 'h2', /Add a thank-you message for Hugh Akston/
    assert_select 'input#donation_event_is_thanks[type="hidden"][value=true]'
    assert_select 'textarea#donation_event_message'
    assert_select 'input[type="radio"]'
    assert_select 'input[type="submit"]'
    assert_select 'a', /actually, no/i
  end

  test "received form for an already-thanked donation" do
    get :edit, {donation_id: @dagny_donation.id, status: "received"}, session_for(@dagny)
    assert_response :success
    assert_select 'p', /Hugh Akston in Boston, MA donated Capitalism: The Unknown Ideal/
    assert_select 'h2', /Add a message for Hugh Akston/
    assert_select 'input#donation_event_is_thanks', false
    assert_select 'textarea#donation_event_message'
    assert_select 'input[type="radio"]', false
    assert_select 'input[type="submit"]'
  end

  test "received form requires login" do
    get :edit, donation_id: @quentin_donation.id, status: "received"
    verify_login_page
  end

  test "received form requires student" do
    get :edit, {donation_id: @dagny_donation.id, status: "received"}, session_for(@hugh)
    verify_wrong_login_page
  end

  # Received

  test "received" do
    event = {message: "", is_thanks: true, public: nil}
    assert_difference "@quentin_donation.events.count" do
      put :update, {donation_id: @quentin_donation.id, donation: {status: "received", event: event}}, session_for(@quentin)
    end
    assert_redirected_to @quentin_request
    assert_match /We've let your donor \(Hugh Akston\) know/, flash[:notice]

    @quentin_donation.reload
    assert @quentin_donation.received?, @quentin_donation.status.to_s
    assert !@quentin_donation.thanked?

    verify_event @quentin_donation, "update_status", detail: "received", is_thanks?: false, public: nil
  end

  test "received with thank-you" do
    event = {message: "Thank you", is_thanks: true, public: true}
    assert_difference "@quentin_donation.events.count" do
      put :update, {donation_id: @quentin_donation.id, donation: {status: "received", event: event}}, session_for(@quentin)
    end
    assert_redirected_to @quentin_request
    assert_match /We've let your donor \(Hugh Akston\) know/, flash[:notice]

    @quentin_donation.reload
    assert @quentin_donation.received?, @quentin_donation.status.to_s
    assert @quentin_donation.thanked?

    verify_event @quentin_donation, "update_status", detail: "received", is_thanks?: true, message: "Thank you", public: true
  end

  test "received with message" do
    event = {message: "It came today"}
    assert_difference "@dagny_donation.events.count" do
      put :update, {donation_id: @dagny_donation.id, donation: {status: "received", event: event}}, session_for(@dagny)
    end
    assert_redirected_to @dagny_request
    assert_match /We've let your donor \(Hugh Akston\) know/, flash[:notice]

    @dagny_donation.reload
    assert @dagny_donation.received?, @dagny_donation.status.to_s

    verify_event @dagny_donation, "update_status", detail: "received", is_thanks?: false, message: "It came today", public: nil
  end

  test "received with thank-you requires explicit public bit" do
    event = {message: "Thank you", is_thanks: true}
    assert_no_difference "@quentin_donation.events.count" do
      put :update, {donation_id: @quentin_donation.id, donation: {status: "received", event: event}}, session_for(@quentin)
    end

    assert_response :success
    assert_select 'h1', /Yes, I have received/
    assert_select '.field_with_errors', /choose/

    @quentin_donation.reload
    assert !@quentin_donation.received?, @quentin_donation.status.to_s
    assert !@quentin_donation.thanked?
  end

  test "received requires login" do
    put :update, {donation_id: @quentin_donation.id, donation: {status: "received"}}
    verify_login_page
  end

  test "received requires student" do
    put :update, {donation_id: @dagny_donation.id, donation: {status: "received"}}, session_for(@hugh)
    verify_wrong_login_page
  end

  # Read form

  test "read form" do
    get :edit, {donation_id: @hank_donation_received.id, status: "read"}, session_for(@hank)
    assert_response :success
    assert_select 'h1', /Yes, I finished reading The Fountainhead/
    assert_select 'textarea#review_text'
    assert_select 'input[type="radio"]'
    assert_select 'input[type="submit"]'
  end

  test "read form requires login" do
    get :edit, {donation_id: @hank_donation_received.id, status: "read"}
    verify_login_page
  end

  test "read form requires student" do
    get :edit, {donation_id: @hank_donation_received.id, status: "read"}, session_for(@cameron)
    verify_wrong_login_page
  end

  # Read

  test "read" do
    params = {donation_id: @hank_donation_received.id, donation: {status: "read"}, review: {text: "I loved it", recommend: true}}
    assert_difference "@hank_donation_received.events.count" do
      post :update, params, session_for(@hank)
    end
    assert_redirected_to new_request_url(from_read: true)
    assert_match /Your donor \(Henry Cameron\) will be glad/, flash[:notice]

    @hank_donation_received.reload
    assert @hank_donation_received.read?

    review = @hank_donation_received.review
    assert_not_nil review
    assert_equal @hank, review.user
    assert_equal "I loved it", review.text
    assert review.recommend?

    assert_select_email do
      # make sure the review got included in the notification
      assert_select 'p', /I loved it/
    end
  end

  test "read with no review" do
    params = {donation_id: @hank_donation_received.id, donation: {status: "read"}, review: {text: ""}}
    assert_difference "@hank_donation_received.events.count" do
      post :update, params, session_for(@hank)
    end
    assert_redirected_to new_request_url(from_read: true)
    assert_match /Your donor \(Henry Cameron\) will be glad/, flash[:notice]

    @hank_donation_received.reload
    assert @hank_donation_received.read?
    assert_nil @hank_donation_received.review
  end

  test "read for student with outstanding request" do
    params = {donation_id: @quentin_donation.id, donation: {status: "read"}, review: {text: ""}}
    assert_difference "@quentin_donation.events.count" do
      post :update, params, session_for(@quentin)
    end
    assert_redirected_to profile_url
    assert_match /Your donor \(Hugh Akston\) will be glad/, flash[:notice]

    @quentin_donation.reload
    assert @quentin_donation.read?
  end

  test "read with review requires recommend bit" do
    params = {donation_id: @hank_donation_received.id, donation: {status: "read"}, review: {text: "It was OK"}}
    assert_no_difference "@hank_donation_received.events.count" do
      post :update, params, session_for(@hank)
      assert_response :success
    end

    assert_select 'h1', /Yes, I finished reading/
    assert_select '.field_with_errors', /choose/

    @hank_donation_received.reload
    assert !@hank_donation_received.read?
    assert_nil @hank_donation_received.review
  end

  test "read requires login" do
    params = {donation_id: @hank_donation_received.id, donation: {status: "read"}, review: {text: ""}}
    assert_no_difference "@hank_donation_received.events.count" do
      post :update, params
      verify_login_page
    end
  end

  test "read requires student" do
    params = {donation_id: @hank_donation_received.id, donation: {status: "read"}, review: {text: ""}}
    assert_no_difference "@hank_donation_received.events.count" do
      post :update, params, session_for(@cameron)
      verify_wrong_login_page
    end
  end
end
