require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    super
    @john = User.new name: "John Galt", email: "galt@gulch.com", location_name: "Atlantis, CO", password: "dagny",
      password_confirmation: "dagny"
  end

  # Associations

  test "requests" do
    assert @howard.requests.any?
    @howard.requests.each {|request| assert_equal @howard, request.user}
  end

  test "pledges" do
    assert @hugh.pledges.any?
    @hugh.pledges.each {|pledge| assert_equal @hugh, pledge.user}
  end

  test "donations" do
    assert @hugh.donations.any?
    @hugh.donations.each {|donation| assert_equal @hugh, donation.user}
  end

  test "reviews" do
    assert_equal [@quentin_review], @quentin.reviews
    assert_equal [], @dagny.reviews
  end

  test "referral" do
    assert_equal @email_referral, @hank.referral
    assert_equal @fb_referral, @stadler.referral
    assert_nil @howard.referral
  end

  test "reminders" do
    assert @hugh.reminders.any?
    @hugh.reminders.each {|reminder| assert_equal @hugh, reminder.user}
    assert !@dagny.reminders.any?
  end

  # Validations

  test "howard is valid" do
    assert @howard.valid?
  end

  test "name is required" do
    @howard.name = nil
    assert @howard.invalid?
  end

  test "email is required" do
    @howard.email = nil
    assert @howard.invalid?
  end

  test "location is required" do
    @howard.location = nil
    assert @howard.invalid?
  end

  test "student fields are not required" do
    @howard.school = nil
    @howard.studying = nil
    assert @howard.valid?
  end

  test "name must be two words" do
    @john.name = "John"
    assert @john.invalid?
    assert_match /first and last/, @john.errors[:name].first
  end

  test "name can't be all caps" do
    @john.name = "JOHN GALT"
    assert @john.invalid?
    assert_match /ALL CAPS/, @john.errors[:name].first
    assert_equal "John Galt", @john.name
  end

  test "name can't be all lowercase" do
    @john.name = "john galt"
    assert @john.invalid?
    assert_match /capitalization/, @john.errors[:name].first
    assert_equal "John Galt", @john.name
  end

  test "password can't be blank" do
    @howard.password = ""
    @howard.password_confirmation = ""
    assert @howard.invalid?
    assert @howard.errors[:password].any?
  end

  test "password confirmation must match" do
    @howard.password = "newpw"
    @howard.password_confirmation = "oops"
    assert @howard.invalid?
    assert @howard.errors[:password].any?
  end

  # Finders

  test "find by email" do
    assert_equal @howard, User.find_by_email(@howard.email)
    assert_equal @howard, User.find_by_email(@howard.email.upcase)
    assert_equal @howard, User.find_by_email(@howard.email.downcase)
    assert_nil User.find_by_email("nobody@nowhere.com")
  end

  test "search" do
    users = User.search "h"
    assert users.any?
    users.each do |user|
      assert user.name =~ /h/i || user.email =~ /h/i
    end
  end

  test "search includes emails" do
    assert_equal [@hugh], User.search("patrickhenry.edu")
  end

  test "search is case-insensitive" do
    assert_equal [@hugh], User.search("HUGH")
  end

  test "volunteer" do
    verify_scope(User, :volunteer) {|user| user.is_volunteer?}
  end

  # Callbacks

  test "email is normalized on save" do
    @john.email = "john@galt.com "
    @john.save!
    assert_equal "john@galt.com", @john.email
  end

  test "name is normalized on save" do
    @john.name = " John  Galt   "
    @john.save!
    assert_equal "John Galt", @john.name
  end

  test "location is created on save" do
    @john.save!
    assert Location.exists?(name: "Atlantis, CO")
  end

  # Signup

  test "create" do
    assert @john.save
    assert User.exists? @john
  end

  test "can't sign up with duplicate email" do
    @john.email = "roark@stanton.edu"
    assert !@john.save
    assert @john.errors[:email].any?
  end

  test "email uniqueness check is case-insensitive" do
    @john.email = "ROARK@stanton.edu"
    assert !@john.save
    assert @john.errors[:email].any?
  end

  test "email must have proper format" do
    @john.email = "johngalt"
    assert !@john.save
    assert @john.errors[:email].any?
  end

  test "is duplicate?" do
    @john.email = "roark@stanton.edu"
    assert @john.is_duplicate?
  end

  # Login

  test "password" do
    assert !@howard.authenticate("wrong")
    assert @howard.authenticate("roark")
  end

  test "login" do
    assert_equal @howard, User.login("roark@stanton.edu", "roark")
  end

  test "wrong password" do
    assert_nil User.login("roark@stanton.edu", "wrong")
  end

  test "wrong email" do
    assert_nil User.login("nobody@nowhere.com", "whatever")
  end

  # Derived attributes

  test "location name" do
    user = create :user
    assert_equal "Anytown, USA", user.location_name
  end

  test "location name setter" do
    user = create :user
    user.location_name = "New City"
    assert_equal "New City", user.location_name
    assert_equal "New City", user.location.name
  end

  test "location name setter can clear location" do
    user = create :user
    user.location_name = nil
    assert_nil user.location_name
    assert_nil user.location
  end

  test "location name setter doesn't create duplicates" do
    user = create :user
    location = create :location, name: "New City"
    user.location_name = "New City"
    assert_equal location, user.location
  end

  test "update detail: added name" do
    @dagny.name = "Dagny Taggart"
    assert_equal "added their full name", @dagny.update_detail
  end

  test "update detail: added address" do
    @dagny.address = "123 Somewhere"
    assert_equal "added a shipping address", @dagny.update_detail
  end

  test "update detail: updated info" do
    @quentin.address = "New Address"
    assert_equal "updated shipping info", @quentin.update_detail
  end

  test "can request? true if no requests" do
    user = create :student
    assert user.can_request?
  end

  test "can request? false if open request" do
    request = create :request
    assert !request.user.can_request?
  end

  test "can request? true if request granted" do
    donation = create :donation
    assert donation.student.can_request?
  end

  test "can request? true if request canceled" do
    request = create :request, :canceled
    assert request.user.can_request?
  end

  test "is volunteer?" do
    assert !@howard.is_volunteer?

    @howard.is_volunteer = true
    @howard.save!
    @howard.reload
    assert @howard.is_volunteer?

    @howard.is_volunteer = false
    @howard.save!
    @howard.reload
    assert !@howard.is_volunteer?
  end

  # Auth token

  test "auth token" do
    assert_equal @howard, User.find_by_auth_token(@howard.auth_token)
  end

  test "auth token invalid" do
    assert_raises User::AuthTokenInvalid do
      User.find_by_auth_token "wrong"
    end
  end

  test "auth token expired" do
    assert_raises User::AuthTokenExpired do
      User.find_by_auth_token @howard.expired_auth_token
    end
  end
end
