require 'test_helper'

class Reminders::SendBooksTest < ActiveSupport::TestCase
  test "all reminders" do
    donation = create :donation
    paid_donation = create :donation, :paid
    sent_donation = create :donation, :sent
    flagged_donation = create :donation, :flagged

    reminders = Reminders::SendBooks.all_reminders
    assert reminders.any?

    reminders.each do |reminder|
      assert_not_nil reminder.user
      reminder.donations.each do |donation|
        assert_equal reminder.user, donation.user
        assert donation.needs_donor_action?, "donation got a reminder but needs no action"
      end
    end

    all_donations = reminders.map {|r| r.donations}.flatten
    assert donation.in?(all_donations), "donation not found"
    assert !paid_donation.in?(all_donations), "paid donation got a reminder"
    assert !sent_donation.in?(all_donations), "sent donation got a reminder"
    assert !flagged_donation.in?(all_donations), "flagged donation got a reminder"
  end

  def new_reminder
    Reminders::SendBooks.new_for_entity @hugh
  end

  test "can send?" do
    assert new_reminder.can_send?
  end

  test "can't send too often" do
    new_reminder.save!
    assert !new_reminder.can_send?

    @howard_request.grant @hugh
    @howard_request.save!

    # Still can't send right away even though we have a new donation
    assert !new_reminder.can_send?
  end

  test "can't send too many" do
    4.times do
      reminder = new_reminder
      reminder.created_at = 1.year.ago
      assert new_reminder.can_send?, "can't send reminder"
      reminder.save!
    end

    assert !new_reminder.can_send?, "should not be able to send too many"

    @quentin_request_open.grant @hugh
    @quentin_request_open.save!

    # Now can send, since we have a new donation
    assert new_reminder.can_send?, "should be able to send after new donation"
  end
end
