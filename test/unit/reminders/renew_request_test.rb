require 'test_helper'

class Reminders::RenewRequestTest < ActiveSupport::TestCase
  def new_reminder
    @request ||= create :request, open_at: 5.weeks.ago
    Reminders::RenewRequest.new_for_entity @request
  end

  def teardown
    @request = nil
    super
  end

  test "all reminders" do
    reminders = Reminders::RenewRequest.all_reminders
    assert reminders.any?, "no reminders!"

    reminders.each do |reminder|
      request = reminder.request
      assert_not_nil request
      assert_equal request.user, reminder.user
      assert request.active?
      assert request.can_renew?
    end
  end

  test "can send?" do
    assert new_reminder.can_send?
  end

  test "can't send too soon" do
    request = create :request
    reminder = Reminders::RenewRequest.new_for_entity request
    assert !reminder.can_send?, "can send reminder too soon"
  end

  test "can't send too often" do
    new_reminder.save!
    Timecop.travel 3.weeks
    assert !new_reminder.can_send?, "can send reminder after 3 weeks"
  end

  test "can't send too many" do
    1.times do
      reminder = new_reminder
      assert reminder.can_send?, "can't send reminder"
      reminder.save!
      Timecop.travel 30.days
    end

    assert !new_reminder.can_send?, "can still send reminder"

    @request.open_at = Time.now
    Timecop.travel 30.days

    assert new_reminder.can_send?, "can't send reminder after reset"
  end
end
