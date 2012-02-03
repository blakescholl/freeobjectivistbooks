require 'test_helper'

class ReminderMailerTest < ActionMailer::TestCase
  test "send reminder" do
    pledges = Pledge.unfulfilled
    assert pledges.any?

    assert_difference "ActionMailer::Base.deliveries.size", pledges.count do
      ReminderMailer.send_reminder :fulfill_pledge
    end
  end

  test "fulfill pledge" do
    mail = ReminderMailer.fulfill_pledge(pledges :hugh_pledge)
    assert_equal "Fulfill your pledge of 5 books on Free Objectivist Books", mail.subject
    assert_equal ["akston@patrickhenry.edu"], mail.to

    mail.deliver
    assert_select_email do
      assert_select 'p', /Hi Hugh/
      assert_select 'p', /Thank you for\s+donating 3 books so far/
      assert_select 'p', /On Jan 15, you pledged to donate 5 books/
      assert_select 'p', /Right now there are 2 students waiting/
      assert_select 'a', /Read their appeals/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "fulfill pledge for donor with no donations" do
    mail = ReminderMailer.fulfill_pledge(pledges :stadler_pledge)
    assert_equal "Fulfill your pledge of 3 books on Free Objectivist Books", mail.subject
    assert_equal ["stadler@scienceinstitute.gov"], mail.to

    mail.deliver
    assert_select_email do
      assert_select 'p', /Hi Robert/
      assert_select 'p', /Thank you for\s+signing up to donate books/
      assert_select 'p', /On Jan 17, you pledged to donate 3 books/
      assert_select 'p', /Right now there are 2 students waiting/
      assert_select 'a', /Read their appeals/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end
end