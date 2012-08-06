require 'test_helper'

class PledgeTest < ActiveSupport::TestCase
  def reason
    "I want to spread these great ideas."
  end

  # Associations

  test "user" do
    assert_equal @hugh, @hugh_pledge.user
  end

  test "referral" do
    assert_equal @fb_referral, @stadler_pledge.referral
    assert_nil @hugh_pledge.referral
  end

  test "reminders" do
    assert_equal [@hugh_reminder], @hugh_pledge.reminders
    assert_equal [], @cameron_pledge.reminders
  end

  # Validations

  test "build" do
    pledge = @hugh.pledges.build quantity: "5", reason: reason
    assert pledge.valid?
  end

  test "quantity is required" do
    pledge = @hugh.pledges.build quantity: "", reason: reason
    assert pledge.invalid?
  end

  test "quantity must be a number" do
    pledge = @hugh.pledges.build quantity: "x", reason: reason
    assert pledge.invalid?
  end

  test "quantity must be positive" do
    pledge = @hugh.pledges.build quantity: "0", reason: reason
    assert pledge.invalid?
  end

  # Derived attributes

  test "fulfilled?" do
    assert @cameron_pledge.fulfilled?
    assert !@hugh_pledge.fulfilled?
  end

  test "fulfilled" do
    verify_scope(Pledge, :unfulfilled) {|pledge| !pledge.fulfilled?}
  end

  test "to testimonial" do
    testimonial = @hugh_pledge.to_testimonial
    assert_equal @hugh_pledge, testimonial.source
    assert_equal 'donor', testimonial.type
    assert_equal "From a donor", testimonial.title
    assert_equal @hugh_pledge.reason, testimonial.text
    assert_equal "Hugh Akston, a donor in Boston, MA", testimonial.attribution
  end
end
