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

  test "renew request" do
    request = create :request, created_at: 9.weeks.ago, open_at: 5.weeks.ago
    reminder = Reminders::RenewRequest.new_for_entity request

    mail = ReminderMailer.send_to_target :renew_request, reminder
    assert_match /Do you still want Book \d+\?/, mail.subject
    assert_equal [request.user.email], mail.to

    assert !reminder.new_record?
    assert_equal mail.subject, reminder.subject

    assert_select_email do
      assert_select 'p', /Hi Student \d+,/
      assert_select 'p', /requested a copy of Book \d+/
      assert_select 'p', /on [A-Z][a-z]+ \d+ \(2 months ago\)/
      assert_select 'a', /Renew your request for Book \d+/
      assert_select 'a', /cancel/
      assert_select 'p', /hear back from you by [A-Z][a-z]+ \d+,/
    end
  end

  test "renew request for very old request doesn't give cancel date" do
    request = create :request, created_at: 9.weeks.ago, open_at: 9.weeks.ago
    reminder = Reminders::RenewRequest.new_for_entity request

    mail = ReminderMailer.send_to_target :renew_request, reminder

    assert_select_email do
      assert_select 'p', /hear back from you soon,/
    end
  end

  test "renew request before Apr 10 mentions new donor drive" do
    Timecop.freeze "2013-04-09"
    request = create :request, created_at: 9.weeks.ago, open_at: 5.weeks.ago
    reminder = Reminders::RenewRequest.new_for_entity request

    mail = ReminderMailer.send_to_target :renew_request, reminder

    assert_select_email do
      assert_select 'p', /new donor drive/
    end
  end

  test "renew request after Apr 10 doesn't mention new donor drive" do
    Timecop.freeze "2013-04-11"
    request = create :request, created_at: 9.weeks.ago, open_at: 5.weeks.ago
    reminder = Reminders::RenewRequest.new_for_entity request

    mail = ReminderMailer.send_to_target :renew_request, reminder

    assert_select_email do
      assert_select 'p', text: /new donor drive/, count: 0
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

  test "send money for donor with one outstanding donation" do
    donor = create :send_money_donor
    donation = create :donation, user: donor, created_at: 1.year.ago
    ActionMailer::Base.deliveries = []

    reminder = Reminders::SendMoney.new_for_entity donor

    mail = ReminderMailer.send_to_target :send_money, reminder
    assert_equal "Please send a contribution of $10 for your donations on Free Objectivist Books", mail.subject
    assert_equal [donor.email], mail.to

    assert !reminder.new_record?
    assert_equal mail.subject, reminder.subject

    assert_select_email do
      assert_select 'p', /Hi Donor \d+/
      assert_select 'p', /contribution from you of \$10/
      assert_select 'p', /cover sending Book \d+ to Student \d+ in Anytown, USA/
      assert_select 'a', /pay/i
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "send money for donor with multiple outstanding donations" do
    donor = create :send_money_donor
    donations = create_list :donation, 3, user: donor, created_at: 1.year.ago
    ActionMailer::Base.deliveries = []

    reminder = Reminders::SendMoney.new_for_entity donor

    mail = ReminderMailer.send_to_target :send_money, reminder
    assert_equal "Please send a contribution of $30 for your donations on Free Objectivist Books", mail.subject
    assert_equal [donor.email], mail.to

    assert !reminder.new_record?
    assert_equal mail.subject, reminder.subject

    assert_select_email do
      assert_select 'p', /Hi Donor \d+/
      assert_select 'p', /contribution from you of \$30/
      assert_select 'p', /will cover the following books/
      assert_select 'li', text: /Book \d+ to Student \d+ in Anytown, USA/, count: 3
      assert_select 'a', /pay/i
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
    @frisco_donation.send! @kira, (Time.now - 2.weeks)
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
