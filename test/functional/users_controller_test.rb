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
    }
  end

  def request_attributes
    { book: "The Fountainhead", other_book: "", reason: request_reason, pledge: "1" }
  end

  def pledge_attributes
    { quantity: 5, reason: pledge_reason }
  end

  # Read

  test "read" do
    get :read
    assert_response :success

    assert_select '#request_book_atlas_shrugged[checked="checked"]'
    assert_select '.error', false
    assert_select '.sidebar h2', "Already signed up?"
  end

  test "read when logged in" do
    get :read, params, session_for(users :howard)
    assert_response :success
    assert_select '.sidebar h2', "Already signed in"
    assert_select '.sidebar p', /already signed in as Howard Roark/
  end

  # Donate

  test "donate" do
    get :donate
    assert_response :success
    assert_select '.error', false
    assert_select '.sidebar h2', "Already signed up?"
  end

  test "donate when logged in" do
    get :donate, params, session_for(users :howard)
    assert_response :success
    assert_select '.sidebar h2', "Already signed in"
    assert_select '.sidebar p', /already signed in as Howard Roark/
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
    assert_equal "The Fountainhead", request.book
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
end
