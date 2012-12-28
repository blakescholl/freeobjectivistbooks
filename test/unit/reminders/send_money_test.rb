require 'test_helper'

class Reminders::SendMoneyTest < ActiveSupport::TestCase
  test "all reminders" do
    reminders = Reminders::SendMoney.all_reminders
    assert reminders.any?

    reminders.each do |reminder|
      assert_not_nil reminder.user
      reminder.donations.each do |donation|
        assert_equal reminder.user, donation.user
        assert donation.donor_mode.send_money?, donation.inspect
        assert donation.price.present?, donation.inspect
        assert !donation.paid?, donation.inspect
      end
    end
  end

  def setup
    @donor = create :send_money_donor
    @donation = create :donation, user: @donor, created_at: 1.year.ago
  end

  def new_reminder
    Reminders::SendMoney.new_for_entity @donor
  end

  test "can send?" do
    assert new_reminder.can_send?
  end

  test "can't send too often" do
    new_reminder.save!
    assert !new_reminder.can_send?

    create :donation, user: @donor

    # Still can't send right away even though we have a new donation
    assert !new_reminder.can_send?
  end

  test "can't send too many" do
    5.times do
      reminder = new_reminder
      reminder.created_at = 1.year.ago
      assert new_reminder.can_send?, "can't send reminder"
      reminder.save!
    end

    assert !new_reminder.can_send?, "should not be able to send too many"

    create :donation, user: @donor, created_at: 4.days.ago

    # Now can send, since we have a new donation
    assert new_reminder.can_send?, "should be able to send after new donation"
  end
end
