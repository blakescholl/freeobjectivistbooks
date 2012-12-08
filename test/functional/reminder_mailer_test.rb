require 'test_helper'

class ReminderMailerTest < ActionMailer::TestCase
  test "fulfill pledge" do
    reminder = Reminders::FulfillPledge.new_for_entity @hugh_pledge

    mail = ReminderMailer.send_to_target :fulfill_pledge, reminder
    assert_equal "Fulfill your pledge of 5 Objectivist books", mail.subject
    assert_equal [@hugh.email], mail.to

    assert !reminder.new_record?
    assert_equal mail.subject, reminder.subject

    assert_select_email do
      assert_select 'p', /Hi Hugh/
      assert_select 'p', /Thank you for\s+donating 3 books so far/
      assert_select 'p', /On Jan 15, you pledged to donate 5 books/
      assert_select 'p', /Right now there are #{Request.not_granted.count} students waiting/
      assert_select 'a', /Read their appeals/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "fulfill pledge for donor with no donations" do
    reminder = Reminders::FulfillPledge.new_for_entity @stadler_pledge

    mail = ReminderMailer.send_to_target :fulfill_pledge, reminder
    assert_equal "Fulfill your pledge of 3 Objectivist books", mail.subject
    assert_equal [@stadler.email], mail.to

    assert !reminder.new_record?
    assert_equal mail.subject, reminder.subject

    assert_select_email do
      assert_select 'p', /Hi Robert/
      assert_select 'p', /Thank you for\s+signing up to donate books/
      assert_select 'p', /On Jan 17, you pledged to donate 3 books/
      assert_select 'p', /Right now there are #{Request.not_granted.count} students waiting/
      assert_select 'a', /Read their appeals/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "send books for donor with one outstanding donation" do
    reminder = Reminders::SendBooks.new_for_entity @hugh

    mail = ReminderMailer.send_to_target :send_books, reminder
    assert_equal "Have you sent The Fountainhead to Quentin Daniels yet?", mail.subject
    assert_equal [@hugh.email], mail.to

    assert !reminder.new_record?
    assert_equal mail.subject, reminder.subject

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

    reminder = Reminders::SendBooks.new_for_entity @hugh

    mail = ReminderMailer.send_to_target :send_books, reminder
    assert_equal "Have you sent your 2 Objectivist books to students yet?", mail.subject
    assert_equal [@hugh.email], mail.to

    assert !reminder.new_record?
    assert_equal mail.subject, reminder.subject

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

  test "confirm receipt unsent" do
    reminder = Reminders::ConfirmReceiptUnsent.new_for_entity @quentin_donation_unsent

    mail = ReminderMailer.send_to_target :confirm_receipt_unsent, reminder
    assert_equal "Have you received The Fountainhead yet?", mail.subject
    assert_equal [@quentin.email], mail.to

    assert !reminder.new_record?
    assert_equal mail.subject, reminder.subject

    assert_select_email do
      assert_select 'p', /Hi Quentin/
      assert_select 'p', /Have you received The Fountainhead/
      assert_select 'p', /Hugh Akston agreed to send you this book on\s+May 1 \(.* ago\)/
      assert_select 'a', /Yes, I have received The Fountainhead/
      assert_select 'a', /No, I have NOT received The Fountainhead/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "confirm receipt" do
    reminder = Reminders::ConfirmReceipt.new_for_entity @quentin_donation

    mail = ReminderMailer.send_to_target :confirm_receipt, reminder
    assert_equal "Have you received The Virtue of Selfishness yet?", mail.subject
    assert_equal [@quentin.email], mail.to

    assert !reminder.new_record?
    assert_equal mail.subject, reminder.subject

    assert_select_email do
      assert_select 'p', /Hi Quentin/
      assert_select 'p', /Have you received The Virtue of Selfishness/
      assert_select 'p', /Hugh Akston has sent you this book \(confirmed on Jan 19\)/
      assert_select 'a', /I have received The Virtue of Selfishness/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "confirm receipt from fulfiller" do
    @frisco_donation.fulfill @kira
    @frisco_donation.update_status! "sent", @kira, (Time.now - 2.weeks)
    ActionMailer::Base.deliveries = []

    reminder = Reminders::ConfirmReceipt.new_for_entity @frisco_donation

    mail = ReminderMailer.send_to_target :confirm_receipt, reminder
    assert_equal "Have you received Objectivism: The Philosophy of Ayn Rand yet?", mail.subject
    assert_equal [@frisco.email], mail.to

    assert !reminder.new_record?
    assert_equal mail.subject, reminder.subject

    assert_select_email do
      assert_select 'p', /Hi Francisco/
      assert_select 'p', /Have you received Objectivism: The Philosophy of Ayn Rand/
      assert_select 'p', /Kira Argounova has sent you this book/
      assert_select 'a', /I have received Objectivism/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "read books" do
    reminder = Reminders::ReadBooks.new_for_entity @hank_donation_received

    mail = ReminderMailer.send_to_target :read_books, reminder
    assert_equal "Have you finished reading The Fountainhead?", mail.subject
    assert_equal [@hank.email], mail.to

    assert !reminder.new_record?
    assert_equal mail.subject, reminder.subject

    assert_select_email do
      assert_select 'p', /Hi Hank/
      assert_select 'p', /You received The Fountainhead on Jan 19\s+\((about )?\d+ \w+ ago\)/
      assert_select 'a', /Yes, I have finished reading The Fountainhead/
      assert_select 'p', /your donor, Henry Cameron/
    end
  end

  test "honor can_send?" do
    Reminders::FulfillPledge.new_for_entity(@hugh_pledge).save!

    reminder = Reminders::FulfillPledge.new_for_entity @hugh_pledge
    assert !reminder.can_send?

    mail = ReminderMailer.send_to_target :fulfill_pledge, reminder
    assert_nil mail
    assert reminder.new_record?
  end
end
