require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    super
    @john = User.new name: "John Galt", email: "galt@gulch.com", location: "Atlantis, CO", password: "dagny",
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

  test "donors with unsent books" do
    verify_scope User, :donors_with_unsent_books do |user|
      user.donor_mode.send_books? && user.donations.active.any? {|donation| donation.needs_sending?}
    end
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

  test "can request?" do
    assert @dagny.can_request?
    assert @hank.can_request?
    assert !@quentin.can_request?
    assert !@howard.can_request?
  end

  test "donor mode" do
    assert @hugh.donor_mode.send_books?, "donor mode is not send_books"
    assert !@hugh.donor_mode.send_money?, "donor mode is send_money"
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
