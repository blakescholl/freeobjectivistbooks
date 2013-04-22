require 'test_helper'

class Reminders::FulfillPledgeTest < ActiveSupport::TestCase
  test "all reminders" do
    create :pledge
    create :pledge, :canceled

    reminders = Reminders::FulfillPledge.all_reminders
    assert reminders.any?

    reminders.each do |reminder|
      assert_not_nil reminder.pledge
      assert_equal reminder.pledge.user, reminder.user
      assert reminder.pledge.active?
      assert !reminder.pledge.fulfilled?
    end
  end

  def new_reminder
    Reminders::FulfillPledge.new_for_entity @cameron_pledge
  end

  test "can send?" do
    assert new_reminder.can_send?
  end

  test "can't send too soon" do
    pledge = @hugh.pledges.build quantity: 5
    pledge.save!

    reminder = Reminders::FulfillPledge.new_for_entity pledge
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
