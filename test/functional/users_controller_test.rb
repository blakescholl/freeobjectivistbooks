require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  def request_reason
    "Everyone tells me I really need to read this book!"
  end

  def pledge_reason
    "I want to spread these great ideas."
  end

  def user_attributes
    {
      name: "John Galt",
      email: "galt@gulch.com",
      location: "Atlantis, CO",
      password: "dagny",
      password_confirmation: "dagny"
      donor_mode: "send_books"
    }
  end

  def request_attributes
    { book_id: @fountainhead.id, other_book: "", reason: request_reason, pledge: "1" }
  end

  def pledge_attributes
    { quantity: 5, reason: pledge_reason }
  end

  # Read

  test "read" do
    get :read
    assert_response :success

    assert_select "#request_book_id_#{@atlas.id}[checked=\"checked\"]"
    assert_select '.error', false
    assert_select '.sidebar h2', "Already signed up?"
  end

  test "read when logged in" do
    get :read, params, session_for(@howard)
    assert_response :success
    assert_select '.sidebar h2', "Already signed in"
    assert_select '.sidebar p', /already signed in as Howard Roark/
  end

  # Donate

  test "donate" do
    get :donate
    assert_response :success
    assert_select 'ul.overview li', /you will send the books/i
    assert_select 'ul.overview li', text: /volunteer will send the books/i, count: 0
    assert_select 'input#user_donor_mode[value="send_books"]'
    assert_select '.error', false
    assert_select '.sidebar h2', "Already signed up?"
  end

  test "donate in send-money mode" do
    get :donate, donor_mode: "send_money"
    assert_response :success
    assert_select 'ul.overview li', text: /you will send the books/i, count: 0
    assert_select 'ul.overview li', /volunteer will send the books/i
    assert_select 'input#user_donor_mode[value="send_money"]'
  end

  test "donate when logged in" do
    get :donate, params, session_for(@howard)
    assert_response :success
    assert_select '.sidebar h2', "Already signed in"
    assert_select '.sidebar p', /already signed in as Howard Roark/
  end

  # Volunteer

  test "volunteer" do
    get :volunteer
    assert_response :success
    assert_select '.error', false
  end

  # Create

  test "create student" do
    user = user_attributes
    request = request_attributes

    post :create, user: user, request: request, from_action: "read"

    user = User.find_by_name "John Galt"
    assert_not_nil user
    assert_equal "galt@gulch.com", user.email
    assert_equal "Atlantis, CO", user.location
    assert user.authenticate "dagny"

    assert_equal user.id, session[:user_id]

    request = user.requests.first
    assert_not_nil request
    assert_equal @fountainhead, request.book
    assert_equal request_reason, request.reason

    assert_equal [], user.pledges

    assert_redirected_to request
  end

  test "create student failure" do
    user = user_attributes
    user[:email] = ""
    user[:password_confirmation] = "dany"

    request = request_attributes
    request.delete :pledge

    post :create, user: user, request: request, from_action: "read"
    assert_response :unprocessable_entity

    assert !User.exists?(name: "John Galt")

    assert_select '.message.error .headline', /problems with your signup/
    assert_select '.field_with_errors', /can't be blank/
    assert_select '.field_with_errors', /didn't match/
    assert_select '.field_with_errors', /must pledge to read/
    assert_select 'form a', text: /log in/i, count: 0
  end

  test "create student with duplicate email" do
    user = user_attributes
    user[:email] = @howard.email

    post :create, user: user, request: request_attributes, from_action: "read"
    assert_response :unprocessable_entity

    assert !User.exists?(name: "John Galt")

    assert_select '.message.error .headline', /problems with your signup/
    assert_select '.field_with_errors', /already an account/
    assert_select 'form a', /log in/i
  end

  test "create donor" do
    user = user_attributes
    pledge = pledge_attributes

    post :create, user: user, pledge: pledge, from_action: "donate"
    assert_redirected_to donate_url

    user = User.find_by_name "John Galt"
    assert_not_nil user
    assert_equal "galt@gulch.com", user.email
    assert_equal "Atlantis, CO", user.location
    assert user.authenticate "dagny"
    assert_equal "send_books", user.donor_mode

    assert_equal user.id, session[:user_id]

    pledge = user.pledges.first
    assert_not_nil pledge
    assert_equal 5, pledge.quantity
    assert_equal pledge_reason, pledge.reason

    assert_equal [], user.requests
  end

  test "create donor in send-money mode" do
    user = user_attributes
    user[:donor_mode] = "send_money"
    pledge = pledge_attributes

    post :create, user: user, pledge: pledge, from_action: "donate"
    assert_redirected_to donate_url

    user = User.find_by_name "John Galt"
    assert_not_nil user
    assert_equal "galt@gulch.com", user.email
    assert_equal "Atlantis, CO", user.location
    assert user.authenticate "dagny"
    assert_equal "send_money", user.donor_mode

    assert_equal user.id, session[:user_id]

    pledge = user.pledges.first
    assert_not_nil pledge
    assert_equal 5, pledge.quantity
    assert_equal pledge_reason, pledge.reason

    assert_equal [], user.requests
  end

  test "create donor failure" do
    user = user_attributes
    user[:email] = ""
    user[:password_confirmation] = "dany"

    pledge = pledge_attributes
    pledge[:quantity] = "x"

    post :create, user: user, pledge: pledge, from_action: "donate"
    assert_response :unprocessable_entity

    assert !User.exists?(name: "John Galt")

    assert_select '.message.error .headline', /problems with your signup/
    assert_select '.field_with_errors', /can't be blank/
    assert_select '.field_with_errors', /didn't match/
    assert_select '.field_with_errors', /Please enter a number/
    assert_select 'form a', text: /log in/i, count: 0
  end

  test "create donor with duplicate email" do
    user = user_attributes
    user[:email] = @hugh.email

    post :create, user: user, pledge: pledge_attributes, from_action: "donate"
    assert_response :unprocessable_entity

    assert !User.exists?(name: "John Galt")

    assert_select '.message.error .headline', /problems with your signup/
    assert_select '.field_with_errors', /already an account/
    assert_select 'form a', /log in/i
  end

  test "create volunteer" do
    user = user_attributes

    post :create, user: user, from_action: "volunteer"

    user = User.find_by_name "John Galt"
    assert_not_nil user
    assert_equal "galt@gulch.com", user.email
    assert_equal "Atlantis, CO", user.location
    assert user.authenticate "dagny"

    assert_equal user.id, session[:user_id]

    assert_equal [], user.requests
    assert_equal [], user.pledges

    assert_redirected_to volunteer_thanks_url
  end

  # Referral tracking

  test "store referral" do
    @request.env['HTTP_REFERER'] = "http://studentsforliberty.org/freeobjectivistbooks"
    get :read, utm_source: "sfl", utm_medium: "blog"
    assert_response :success
    assert_not_nil session[:referral_id]

    referral = Referral.find session[:referral_id]
    assert_equal "sfl", referral.source
    assert_equal "blog", referral.medium
    assert_match %r{^http://test.host/signup/read\?}, referral.landing_url
    assert_equal "http://studentsforliberty.org/freeobjectivistbooks", referral.referring_url
  end

  test "save referral on request" do
    user = user_attributes
    request = request_attributes
    session[:referral_id] = @email_referral.id
    post :create, user: user, request: request, from_action: "read"

    user = User.find_by_name "John Galt"
    assert_equal @email_referral, user.referral
    assert_equal @email_referral, user.requests.first.referral
  end

  test "save referral on pledge" do
    user = user_attributes
    pledge = pledge_attributes
    session[:referral_id] = @fb_referral.id
    post :create, user: user, pledge: pledge, from_action: "donate"

    user = User.find_by_name "John Galt"
    assert_equal @fb_referral, user.referral
    assert_equal @fb_referral, user.pledges.first.referral
  end
end
