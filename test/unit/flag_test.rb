require 'test_helper'

class FlagTest < ActiveSupport::TestCase
  # Fix

  test "fix: added address" do
    donation = create :donation_for_request_no_address
    flag = donation.flag
    assert_not_nil flag

    event = flag.fix student_name: flag.student_name, address: "123 Independence St", fix_message: ""

    assert flag.fixed?
    assert !flag.donation.flagged?

    assert_equal "added a shipping address", flag.fix_type
    assert flag.fix_message.blank?

    assert_equal "fix", event.type
    assert_equal flag.student, event.user
  end

  test "fix: updated info" do
    flag = create :flag

    event = flag.fix student_name: flag.student_name, address: "New Address", fix_message: "I have a new address"

    assert flag.fixed?
    assert !flag.donation.flagged?

    assert_equal "updated shipping info", flag.fix_type
    assert_equal "I have a new address", flag.fix_message

    assert_equal "fix", event.type
    assert_equal flag.student, event.user
  end

  test "fix: message only" do
    flag = create :flag

    event = flag.fix student_name: flag.student_name, address: flag.address, fix_message: "just a message"

    assert flag.fixed?
    assert !flag.donation.flagged?

    assert_nil flag.fix_type
    assert_equal "just a message", flag.fix_message

    assert_equal "fix", event.type
    assert_equal flag.student, event.user
  end

  test "fix requires address" do
    flag = create :flag

    event = flag.fix student_name: flag.student_name, address: "", message: "Here you go"
    assert !flag.valid?
  end
end
