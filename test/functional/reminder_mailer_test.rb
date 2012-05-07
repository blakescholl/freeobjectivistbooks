require 'test_helper'

class ReminderMailerTest < ActionMailer::TestCase
  test "send reminder" do
    Mailgun::Campaign.test_mode = true
    pledges = Pledge.unfulfilled
    assert pledges.any?

    assert_difference "ActionMailer::Base.deliveries.size", pledges.count do
      Reminder.send_reminder_mails :fulfill_pledge
    end
  end

  test "fulfill pledge" do
    assert_difference "Reminder.count" do
      @mail = ReminderMailer.send_to_target :fulfill_pledge, Reminder.new_fulfill_pledge(@hugh_pledge)
    end
    assert_equal "Fulfill your pledge of 5 books on Free Objectivist Books", @mail.subject
    assert_equal ["akston@patrickhenry.edu"], @mail.to

    reminder = Reminder.last
    assert_equal @hugh, reminder.user
    assert_equal 'fulfill_pledge', reminder.type
    assert_equal [@hugh_pledge], reminder.pledges
    assert_equal @mail.subject, reminder.subject

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
    assert_difference "Reminder.count" do
      @mail = ReminderMailer.send_to_target :fulfill_pledge, Reminder.new_fulfill_pledge(@stadler_pledge)
    end
    assert_equal "Fulfill your pledge of 3 books on Free Objectivist Books", @mail.subject
    assert_equal ["stadler@scienceinstitute.gov"], @mail.to

    reminder = Reminder.last
    assert_equal @stadler, reminder.user
    assert_equal 'fulfill_pledge', reminder.type
    assert_equal [@stadler_pledge], reminder.pledges
    assert_equal @mail.subject, reminder.subject

    assert_select_email do
      assert_select 'p', /Hi Robert/
      assert_select 'p', /Thank you for\s+signing up to donate books/
      assert_select 'p', /On Jan 17, you pledged to donate 3 books/
      assert_select 'p', /Right now there are 2 students waiting/
      assert_select 'a', /Read their appeals/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "send books for donor with one outstanding donation" do
    assert_difference "Reminder.count" do
      @mail = ReminderMailer.send_to_target :send_books, Reminder.new_send_books(@hugh)
    end
    assert_equal "Have you sent The Fountainhead to Quentin Daniels yet?", @mail.subject
    assert_equal ["akston@patrickhenry.edu"], @mail.to

    reminder = Reminder.last
    assert_equal @hugh, reminder.user
    assert_equal 'send_books', reminder.type
    assert_equal [@quentin_donation_unsent], reminder.donations
    assert_equal @mail.subject, reminder.subject

    assert_select_email do
      assert_select 'p', /Hi Hugh/
      assert_select 'p', /said you would donate The Fountainhead to Quentin Daniels in Boston, MA/
      assert_select 'p', /notify the student that the book is on its way/
      assert_select 'a', /donations/
      assert_select 'p', /please send it soon/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "send books for donor with multiple outstanding donations" do
    @dagny_donation.address = "123 Somewhere"
    @dagny_donation.flagged = false
    @dagny_donation.save!

    assert_difference "Reminder.count" do
      @mail = ReminderMailer.send_to_target :send_books, Reminder.new_send_books(@hugh)
    end
    assert_equal "Have you sent your 2 books to students from Free Objectivist Books yet?", @mail.subject
    assert_equal ["akston@patrickhenry.edu"], @mail.to

    reminder = Reminder.last
    assert_equal @hugh, reminder.user
    assert_equal 'send_books', reminder.type
    assert_equal [@quentin_donation_unsent, @dagny_donation].to_set, reminder.donations.to_set
    assert_equal @mail.subject, reminder.subject

    assert_select_email do
      assert_select 'p', /Hi Hugh/
      assert_select 'p', /said you would donate these books/
      assert_select 'li', minimum: 2
      assert_select 'li', /Capitalism: The Unknown Ideal to Dagny in Chicago, IL/
      assert_select 'li', /The Fountainhead to Quentin Daniels in Boston, MA/
      assert_select 'p', /notify the students that the books are on their way/
      assert_select 'a', /donations/
      assert_select 'p', /please send them soon/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "confirm receipt" do
    assert_difference "Reminder.count" do
      @mail = ReminderMailer.send_to_target :confirm_receipt, Reminder.new_confirm_receipt(@quentin_donation)
    end
    assert_equal "Have you received The Virtue of Selfishness yet?", @mail.subject
    assert_equal ["quentin@mit.edu"], @mail.to

    reminder = Reminder.last
    assert_equal @quentin, reminder.user
    assert_equal 'confirm_receipt', reminder.type
    assert_equal [@quentin_donation], reminder.donations
    assert_equal @mail.subject, reminder.subject

    assert_select_email do
      assert_select 'p', /Hi Quentin/
      assert_select 'p', /Have you received The Virtue of Selfishness/
      assert_select 'p', /Hugh Akston has sent you this book \(confirmed on Jan 19\)/
      assert_select 'a', /I have received The Virtue of Selfishness/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "read books" do
    assert_difference "Reminder.count" do
      @mail = ReminderMailer.send_to_target :read_books, Reminder.new_read_books(@hank_donation_received)
    end
    assert_equal "Have you finished reading The Fountainhead?", @mail.subject
    assert_equal ["hank@rearden.com"], @mail.to

    reminder = Reminder.last
    assert_equal @hank, reminder.user
    assert_equal 'read_books', reminder.type
    assert_equal [@hank_donation_received], reminder.donations
    assert_equal @mail.subject, reminder.subject

    assert_select_email do
      assert_select 'p', /Hi Hank/
      assert_select 'p', /You received The Fountainhead on Jan 19\s+\((about )?\d+ \w+ ago\)/
      assert_select 'a', /Yes, I have finished reading The Fountainhead/
      assert_select 'p', /your donor, Henry Cameron/
    end
  end
end
