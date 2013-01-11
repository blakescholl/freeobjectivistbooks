require 'test_helper'

class MessagesControllerTest < ActionController::TestCase
  def params(donation, message = nil)
    params = {donation_id: donation.id}
    params[:event] = {message: message} if message
    params
  end

  def thank_params(donation, message = nil, options = {})
    params = params(donation, message)
    params[:is_thanks] = true
    if params[:event]
      params[:event][:is_thanks] = true
      params[:event].merge! options
    end
    params
  end

  # New

  test "new for donor" do
    get :new, params(@quentin_donation), session_for(@hugh)
    assert_response :success
    assert_select 'h1', /Send a message to Quentin Daniels/
    assert_select '.overview', /Quentin Daniels requested The Virtue of Selfishness/
    assert_select 'textarea#event_message'
    assert_select 'input[type="submit"]'
    assert_select 'a', 'Cancel'
  end

  test "new for student" do
    get :new, params(@quentin_donation), session_for(@quentin)
    assert_response :success
    assert_select 'h1', /Send a message to Hugh Akston/
    assert_select '.overview', /Hugh Akston donated The Virtue of Selfishness/
    assert_select 'textarea#event_message'
    assert_select 'input[type="submit"]'
    assert_select 'a', 'Cancel'
  end

  test "new for student book not sent" do
    get :new, params(@dagny_donation), session_for(@dagny)
    assert_response :success
    assert_select 'h1', /Send a message to Hugh Akston/
    assert_select '.overview', /Hugh Akston donated Capitalism: The Unknown Ideal/
    assert_select 'textarea#event_message'
    assert_select 'input[type="submit"]'
    assert_select 'a', 'Cancel'
  end

  test "new for fulfiller" do
    @frisco_donation.fulfill @kira

    get :new, params(@frisco_donation), session_for(@kira)
    assert_response :success
    assert_select 'h1', /Send a message to Francisco d&#x27;Anconia and Henry Cameron/
    assert_select 'p', /Francisco d&#x27;Anconia requested Objectivism/
    assert_select 'p', /Henry Cameron donated Objectivism/
  end

  test "new for student with fulfiller" do
    @frisco_donation.fulfill @kira

    get :new, params(@frisco_donation), session_for(@frisco)
    assert_response :success
    assert_select 'h1', /Send a message to Henry Cameron and Kira Argounova/
    assert_select 'p', /Henry Cameron donated Objectivism/
    assert_select 'p', /Kira Argounova.*sent/
  end

  test "new for donor with fulfiller" do
    @frisco_donation.fulfill @kira

    get :new, params(@frisco_donation), session_for(@cameron)
    assert_response :success
    assert_select 'h1', /Send a message to Francisco d&#x27;Anconia and Kira Argounova/
    assert_select 'p', /Francisco d&#x27;Anconia requested Objectivism/
    assert_select 'p', /Kira Argounova.*sent/
  end

  test "new requires login" do
    get :new, params(@quentin_donation)
    verify_login_page
  end

  test "new requires student or donor" do
    get :new, params(@quentin_donation), session_for(@howard)
    verify_wrong_login_page
  end

  # New thanks

  test "new thanks" do
    get :new, thank_params(@hank_donation), session_for(@hank)
    assert_response :success
    assert_select 'h1', /Thank Henry Cameron/
    assert_select 'p', /Henry Cameron donated Atlas Shrugged/
    assert_select 'textarea#event_message'
    assert_select 'input[type="radio"]'
    assert_select 'input[type="submit"]'
  end

  test "new thanks with fulfiller" do
    @frisco_donation.fulfill @kira

    get :new, thank_params(@frisco_donation), session_for(@frisco)
    assert_response :success
    assert_select 'h1', /Thank Henry Cameron and Kira Argounova/
    assert_select 'p', /Henry Cameron donated Objectivism/
    assert_select 'p', /Kira Argounova.*sent/
    assert_select 'textarea#event_message'
    assert_select 'input[type="radio"]'
    assert_select 'input[type="submit"]'
  end

  test "new thanks requires login" do
    get :new, thank_params(@hank_donation)
    verify_login_page
  end

  test "new thanks requires student" do
    get :new, thank_params(@hank_donation), session_for(@howard)
    verify_wrong_login_page
  end

  # Create

  test "create from student" do
    assert_difference "@quentin_donation.events.count" do
      post :create, params(@quentin_donation, "Hi Hugh!"), session_for(@quentin)
    end

    assert_redirected_to @quentin_request
    assert_match /your message to Hugh Akston/i, flash[:notice]

    verify_event @quentin_donation, "message", user: @quentin, message: "Hi Hugh!", notified?: true
  end

  test "create from donor" do
    assert_difference "@quentin_donation.events.count" do
      post :create, params(@quentin_donation, "Hi Quentin!"), session_for(@hugh)
    end

    assert_redirected_to @quentin_request
    assert_match /your message to Quentin Daniels/i, flash[:notice]

    verify_event @quentin_donation, "message", user: @hugh, message: "Hi Quentin!", notified?: true
  end

  test "create from fulfiller" do
    @frisco_donation.fulfill @kira

    assert_difference "@frisco_donation.events.count" do
      post :create, params(@frisco_donation, "Hi everybody!"), session_for(@kira)
    end

    assert_redirected_to @frisco_request
    assert_match /your message to Francisco d'Anconia and Henry Cameron/i, flash[:notice]

    verify_event @frisco_donation, "message", user: @kira, message: "Hi everybody!", notified?: true
  end

  test "create requires message" do
    assert_no_difference "@quentin_donation.events.count" do
      post :create, params(@quentin_donation, ""), session_for(@quentin)
    end

    assert_response :success
    assert_select 'h1', /Send a message/i
  end

  test "create requires login" do
    post :create, params(@quentin_donation, "Hello")
    verify_login_page
  end

  test "create requires student or donor" do
    post :create, params(@quentin_donation, "Hello"), session_for(@howard)
    verify_wrong_login_page
  end

  # Thank

  test "create thanks" do
    assert_difference "@hank_donation.events.count" do
      post :create, thank_params(@hank_donation, "Thanks so much!", public: true), session_for(@hank)
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
      post :create, thank_params(@frisco_donation, "Thanks a lot!", public: false), session_for(@frisco)
    end

    assert_redirected_to @frisco_request
    assert_match /sent your thanks to Henry Cameron and Kira Argounova/i, flash[:notice]

    @frisco_donation.reload
    assert @frisco_donation.thanked?

    verify_event @frisco_donation, "message", is_thanks?: true, message: "Thanks a lot!", notified?: true
  end

  test "create thanks requires message" do
    assert_no_difference "@hank_donation.events.count" do
      post :create, thank_params(@hank_donation, "", public: true), session_for(@hank)
    end

    assert_response :success
    assert_select 'h1', /thank/i
    assert_select '.field_with_errors', /enter a message/

    @hank_donation.reload
    assert !@hank_donation.thanked?
  end

  test "create thanks requires explicit public bit" do
    assert_no_difference "@hank_donation.events.count" do
      post :create, thank_params(@hank_donation, "Thanks so much!"), session_for(@hank)
    end

    assert_response :success
    assert_select 'h1', /thank/i
    assert_select '.field_with_errors', /choose/

    @hank_donation.reload
    assert !@hank_donation.thanked?
  end

  test "create thanks requires login" do
    post :create, thank_params(@hank_donation, "Thanks so much!", public: true)
    verify_login_page
  end

  test "create thanks requires student" do
    post :create, thank_params(@hank_donation, "Thanks so much!", public: true), session_for(@cameron)
    verify_wrong_login_page
  end
end
