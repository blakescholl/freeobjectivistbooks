require 'test_helper'

class ReminderJobTest < ActiveSupport::TestCase
  test "send all reminders" do
    Mailgun::Campaign.test_mode = true
    reminders = ReminderJob.send_all_reminders
    assert reminders.any?
    assert_equal reminders.size, ActionMailer::Base.deliveries.size
  end
end
