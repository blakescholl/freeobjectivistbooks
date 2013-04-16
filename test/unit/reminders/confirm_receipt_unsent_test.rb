require 'test_helper'

class Reminders::ConfirmReceiptUnsentTest < ActiveSupport::TestCase
  test "all reminders" do
    reminders = Reminders::ConfirmReceiptUnsent.all_reminders
    assert reminders.any?

    reminders.each do |reminder|
      donation = reminder.donation
      assert_not_nil donation
      assert_equal donation.student, reminder.user
      assert donation.needs_donor_action?
    end
  end

  def new_reminder
    Reminders::ConfirmReceiptUnsent.new_for_entity @quentin_donation_unsent
  end

  test "can send?" do
    assert new_reminder.can_send?
  end

  test "can't send too soon" do
    @quentin_donation_unsent.created_at = Time.now
    @quentin_donation_unsent.save!

    reminder = Reminders::ConfirmReceiptUnsent.new_for_entity @quentin_donation_unsent
    assert !reminder.can_send?
  end

  test "can't send too often" do
    new_reminder.save!
    assert !new_reminder.can_send?
  end

  test "can't send too many" do
    3.times do
      reminder = new_reminder
      reminder.created_at = 1.year.ago
      assert new_reminder.can_send?, "can't send reminder"
      reminder.save!
    end

    assert !new_reminder.can_send?, "can still send reminder"
  end
end
