require 'test_helper'

class Reminders::FixFlagTest < ActiveSupport::TestCase
  def setup
    @flag = create :flag
    Timecop.travel 1.week
  end

  test "all reminders" do
    reminders = Reminders::FixFlag.all_reminders
    assert reminders.any?

    reminders.each do |reminder|
      assert_not_nil reminder.donation
      assert reminder.donation.flagged?
      assert !reminder.donation.sent?

      assert_not_nil reminder.flag
      assert_equal reminder.donation, reminder.flag.donation
      assert_equal reminder.flag, reminder.donation.flag
      assert !reminder.flag.fixed?

      assert_equal reminder.donation.student, reminder.user
    end
  end

  def new_reminder
    Reminders::FixFlag.new_for_entity @flag
  end

  test "can send?" do
    assert new_reminder.can_send?
  end

  test "can't send too soon" do
    flag = create :flag
    reminder = Reminders::FixFlag.new_for_entity flag
    assert !reminder.can_send?
  end

  test "can't send too often" do
    new_reminder.save!
    assert !new_reminder.can_send?
  end

  test "can't send too many" do
    3.times do
      Timecop.travel 1.week
      reminder = new_reminder
      assert new_reminder.can_send?, "can't send reminder"
      reminder.save!
    end

    assert !new_reminder.can_send?, "can still send reminder"
  end
end
