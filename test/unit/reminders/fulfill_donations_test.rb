require 'test_helper'

class Reminders::FulfillDonationsTest < ActiveSupport::TestCase
  test "all reminders" do
    reminders = Reminders::FulfillDonations.all_reminders
    assert reminders.any?, "no reminders"

    reminders.each do |reminder|
      assert reminder.user.is_volunteer?
    end
  end

  def setup
    @user = create :volunteer
  end

  def new_reminder
    Reminders::FulfillDonations.new_for_entity @user
  end

  test "can send?" do
    assert new_reminder.can_send?
  end

  test "can't send too soon" do
    create :fulfillment, user: @user
    assert !new_reminder.can_send?
  end

  test "can't send too often" do
    new_reminder.save!
    assert !new_reminder.can_send?
  end

  test "can't send when no work to be done" do
    Donation.needs_fulfillment.each {|donation| donation.fulfill! @user}
    assert !new_reminder.can_send?, "can still send reminder"
  end
end
