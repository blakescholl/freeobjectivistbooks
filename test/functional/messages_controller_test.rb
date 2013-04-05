require 'test_helper'

class MessagesControllerTest < ActionController::TestCase
  def new_params(donation, options = {})
    params = {donation_id: donation.id}
    params[:reply_to_event_id] = options[:reply_to_event].id if options[:reply_to_event]
    params
  end

  def new_thank_params(donation)
    params = new_params(donation)
    params[:is_thanks] = true
    params
  end

  def create_params(donation, message, options = {})
    params = {donation_id: donation.id}
    params[:event] = {message: message}
    params[:event][:recipient_id] = options[:recipient].id if options[:recipient]
    params[:event][:reply_to_event_id] = options[:reply_to_event].id if options[:reply_to_event]
    params
  end

  def create_thank_params(donation, message, options = {})
    params = create_params(donation, message)
    params[:is_thanks] = true
    params[:event][:is_thanks] = true
    params[:event][:public] = options[:public] unless options[:public].nil?
    params
  end

  # New

  def verify_recipient_radios(user1, user2, options = {})
    assert_select "input[type=radio][name='event[recipient_id]']", 3
    assert_select "input[type=radio][name='event[recipient_id]'][value]", 2
    assert_select "input[type=radio][name='event[recipient_id]'][value=#{user1.id}]", 1
    assert_select "input[type=radio][name='event[recipient_id]'][value=#{user2.id}]", 1

    assert_select "input[type=radio][name='event[recipient_id]'][checked]"
    assert_select "input[type=radio][name='event[recipient_id]'][value=#{user1.id}][checked]", (options[:selected] == user1)
    assert_select "input[type=radio][name='event[recipient_id]'][value=#{user2.id}][checked]", (options[:selected] == user2)
  end

  def verify_no_recipient_radios
    assert_select "input[type=radio][name='event[recipient_id]']", false
  end

  test "new for donor" do
    get :new, new_params(@quentin_donation), session_for(@hugh)
    assert_response :success
    assert_select 'h1', /Send a message to\s+Quentin Daniels/
    assert_select '.overview', /Quentin Daniels requested The Virtue of Selfishness/
    assert_select 'textarea#event_message'
    verify_no_recipient_radios
    assert_select 'input[type="submit"]'
    assert_select 'a', 'Cancel'
  end

  test "new for student" do
    get :new, new_params(@quentin_donation), session_for(@quentin)
    assert_response :success
    assert_select 'h1', /Send a message to\s+Hugh Akston/
    assert_select '.overview', /Hugh Akston donated The Virtue of Selfishness/
    assert_select 'textarea#event_message'
    verify_no_recipient_radios
    assert_select 'input[type="submit"]'
    assert_select 'a', 'Cancel'
  end

  test "new for student book not sent" do
    get :new, new_params(@dagny_donation), session_for(@dagny)
    assert_response :success
    assert_select 'h1', /Send a message to\s+Hugh Akston/
    assert_select '.overview', /Hugh Akston donated Capitalism: The Unknown Ideal/
    assert_select 'textarea#event_message'
    verify_no_recipient_radios
    assert_select 'input[type="submit"]'
    assert_select 'a', 'Cancel'
  end

  test "new for fulfiller" do
    @frisco_donation.fulfill @kira

    get :new, new_params(@frisco_donation), session_for(@kira)
    assert_response :success
    assert_select 'h1', /Send a message to\s+Francisco d&#x27;Anconia or Henry Cameron/
    assert_select 'p', /Francisco d&#x27;Anconia requested Objectivism/
    assert_select 'p', /Henry Cameron donated Objectivism/
    verify_recipient_radios @frisco, @cameron, selected: @frisco
  end

  test "new for student with fulfiller" do
    @frisco_donation.fulfill @kira

    get :new, new_params(@frisco_donation), session_for(@frisco)
    assert_response :success
    assert_select 'h1', /Send a message to\s+Henry Cameron or Kira Argounova/
    assert_select 'p', /Henry Cameron donated Objectivism/
    assert_select 'p', /Kira Argounova.*sent/
    verify_recipient_radios @cameron, @kira
  end

  test "new for donor with fulfiller" do
    @frisco_donation.fulfill @kira

    get :new, new_params(@frisco_donation), session_for(@cameron)
    assert_response :success
    assert_select 'h1', /Send a message to\s+Francisco d&#x27;Anconia or Kira Argounova/
    assert_select 'p', /Francisco d&#x27;Anconia requested Objectivism/
    assert_select 'p', /Kira Argounova.*sent/
    verify_recipient_radios @frisco, @kira, selected: @frisco
  end

  test "new reply" do
    fulfillment = create :fulfillment
    orig = fulfillment.donation.thank!

    get :new, new_params(fulfillment.donation, reply_to_event: orig), session_for(fulfillment.user)
    assert_response :success
    assert_select 'h1', /Reply to\s+Student \d+$/
    assert_select 'p', /Student \d+ requested Book \d+/
    verify_no_recipient_radios
  end

  test "new requires login" do
    get :new, new_params(@quentin_donation)
    verify_login_page
  end

  test "new requires student or donor" do
    get :new, new_params(@quentin_donation), session_for(@howard)
    verify_wrong_login_page
  end

  test "new reply requires relevant reply-to event" do
    donation = create :donation
    donation2 = create :donation, user: donation.user
    orig = donation2.thank!

    get :new, new_params(donation, reply_to_event: orig), session_for(donation.user)
    assert_response 500
  end

  # New thanks

  test "new thanks" do
    get :new, new_thank_params(@hank_donation), session_for(@hank)
    assert_response :success
    assert_select 'h1', /Thank Henry Cameron/
    assert_select 'p', /Henry Cameron donated Atlas Shrugged/
    assert_select 'textarea#event_message'
    assert_select "input[type=radio][name='event[public]']", 2
    assert_select 'input[type="submit"]'
  end

  test "new thanks with fulfiller" do
    @frisco_donation.fulfill @kira

    get :new, new_thank_params(@frisco_donation), session_for(@frisco)
    assert_response :success
    assert_select 'h1', /Thank Henry Cameron and Kira Argounova/
    assert_select 'p', /Henry Cameron donated Objectivism/
    assert_select 'p', /Kira Argounova.*sent/
    assert_select 'textarea#event_message'
    assert_select "input[type=radio][name='event[public]']", 2
    assert_select 'input[type="submit"]'
  end

  test "new thanks requires login" do
    get :new, new_thank_params(@hank_donation)
    verify_login_page
  end

  test "new thanks requires student" do
    get :new, new_thank_params(@hank_donation), session_for(@howard)
    verify_wrong_login_page
  end

  # Create

  test "create from student" do
    assert_difference "@quentin_donation.events.count" do
      post :create, create_params(@quentin_donation, "Hi Hugh!"), session_for(@quentin)
    end

    assert_redirected_to @quentin_request
    assert_match /your message to\s+Hugh Akston/i, flash[:notice]

    verify_event @quentin_donation, "message", user: @quentin, message: "Hi Hugh!", recipient: nil, notified?: true
  end

  test "create from donor" do
    assert_difference "@quentin_donation.events.count" do
      post :create, create_params(@quentin_donation, "Hi Quentin!"), session_for(@hugh)
    end

    assert_redirected_to @quentin_request
    assert_match /your message to\s+Quentin Daniels/i, flash[:notice]

    verify_event @quentin_donation, "message", user: @hugh, message: "Hi Quentin!", recipient: nil, notified?: true
  end

  test "create from fulfiller" do
    @frisco_donation.fulfill @kira

    assert_difference "@frisco_donation.events.count" do
      post :create, create_params(@frisco_donation, "Hi everybody!"), session_for(@kira)
    end

    assert_redirected_to @frisco_request
    assert_match /your message to\s+Francisco d'Anconia and Henry Cameron/i, flash[:notice]

    verify_event @frisco_donation, "message", user: @kira, message: "Hi everybody!", recipient: nil, notified?: true
  end

  test "create private" do
    fulfillment = create :fulfillment

    assert_difference "fulfillment.donation.events.count" do
      post :create, create_params(fulfillment.donation, "Psst", recipient: fulfillment.student), session_for(fulfillment.user)
    end

    assert_redirected_to fulfillment.request
    assert_match /your message to\s+Student \d+\./, flash[:notice]

    verify_event fulfillment.donation, "message", user: fulfillment.user, message: "Psst", recipient: fulfillment.student, notified?: true
  end

  test "create reply" do
    fulfillment = create :fulfillment
    orig = fulfillment.donation.thank!

    assert_difference "fulfillment.donation.events.count" do
      post :create, create_params(fulfillment.donation, "You're welcome", reply_to_event: orig), session_for(fulfillment.user)
    end

    assert_redirected_to fulfillment.request
    assert_match /your message to\s+Student \d+\./, flash[:notice]

    verify_event fulfillment.donation, "message", user: fulfillment.user, message: "You're welcome", reply_to_event: orig, notified?: true
  end

  test "create requires message" do
    assert_no_difference "@quentin_donation.events.count" do
      post :create, create_params(@quentin_donation, ""), session_for(@quentin)
    end

    assert_response :success
    assert_select 'h1', /Send a message/i
    assert_select '.field_with_errors'
  end

  test "create requires login" do
    post :create, create_params(@quentin_donation, "Hello")
    verify_login_page
  end

  test "create requires student or donor" do
    post :create, create_params(@quentin_donation, "Hello"), session_for(@howard)
    verify_wrong_login_page
  end

  test "create requires valid recipient" do
    fulfillment = create :fulfillment
    user = create :user

    assert_no_difference "fulfillment.donation.events.count" do
      post :create, create_params(fulfillment.donation, "Hello", recipient: user), session_for(fulfillment.donor)
    end

    assert_response :success
    assert_select 'h1', /Send a message/i
    assert_select '.field_with_errors'
  end

  test "create reply requires relevant reply-to event" do
    donation = create :donation
    donation2 = create :donation, user: donation.user
    orig = donation2.thank!

    assert_no_difference "donation.events.count" do
      post :create, create_params(donation, "Hello", reply_to_event: orig), session_for(donation.user)
    end

    assert_response 500
  end

  # Thank

  test "create thanks" do
    assert_difference "@hank_donation.events.count" do
      post :create, create_thank_params(@hank_donation, "Thanks so much!", public: true), session_for(@hank)
    end

    assert_redirected_to @hank_request
    assert_match /sent your thanks to Henry Cameron/i, flash[:notice]

    @hank_donation.reload
    assert @hank_donation.thanked?

    verify_event @hank_donation, "message", is_thanks?: true, message: "Thanks so much!", notified?: true
  end

  test "create thanks with fulfiller" do
    @frisco_donation.fulfill @kira

    assert_difference "@frisco_donation.events.count" do
      post :create, create_thank_params(@frisco_donation, "Thanks a lot!", public: false), session_for(@frisco)
    end

    assert_redirected_to @frisco_request
    assert_match /sent your thanks to Henry Cameron and Kira Argounova/i, flash[:notice]

    @frisco_donation.reload
    assert @frisco_donation.thanked?

    verify_event @frisco_donation, "message", is_thanks?: true, message: "Thanks a lot!", notified?: true
  end

  test "create thanks requires message" do
    assert_no_difference "@hank_donation.events.count" do
      post :create, create_thank_params(@hank_donation, "", public: true), session_for(@hank)
    end

    assert_response :success
    assert_select 'h1', /thank/i
    assert_select '.field_with_errors', /enter a message/

    @hank_donation.reload
    assert !@hank_donation.thanked?
  end

  test "create thanks requires explicit public bit" do
    assert_no_difference "@hank_donation.events.count" do
      post :create, create_thank_params(@hank_donation, "Thanks so much!"), session_for(@hank)
    end

    assert_response :success
    assert_select 'h1', /thank/i
    assert_select '.field_with_errors', /choose/

    @hank_donation.reload
    assert !@hank_donation.thanked?
  end

  test "create thanks requires login" do
    post :create, create_thank_params(@hank_donation, "Thanks so much!", public: true)
    verify_login_page
  end

  test "create thanks requires student" do
    post :create, create_thank_params(@hank_donation, "Thanks so much!", public: true), session_for(@cameron)
    verify_wrong_login_page
  end
end
