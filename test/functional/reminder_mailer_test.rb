require 'test_helper'

class ReminderMailerTest < ActionMailer::TestCase
  def verify_reminder(reminder, subject = nil, &block)
    ActionMailer::Base.deliveries = []

    mail = ReminderMailer.send_to_target reminder.class.type_name, reminder
    case subject
    when String then assert_equal subject, mail.subject
    when Regexp then assert_match subject, mail.subject
    end
    assert_equal [reminder.user.email], mail.to

    assert !reminder.new_record?
    assert_equal mail.subject, reminder.subject

    assert mail.body.encoded.present?, "mail is blank"
    assert_select_email &block
  end

  test "fulfill pledge" do
    reminder = Reminders::FulfillPledge.new_for_entity @hugh_pledge

    verify_reminder reminder, "Fulfill your pledge of 5 Objectivist books" do
      assert_select 'p', /Hi Hugh/
      assert_select 'p', /Thank you for\s+donating 3 books so far/
      assert_select 'p', /You have pledged to donate 5 books/
      assert_select 'p', /Right now there are #{Request.not_granted.count} students waiting/
      assert_select 'a', /Read their appeals/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "fulfill pledge for donor with no donations" do
    reminder = Reminders::FulfillPledge.new_for_entity @stadler_pledge

    verify_reminder reminder, "Fulfill your pledge of 3 Objectivist books" do
      assert_select 'p', /Hi Robert/
      assert_select 'p', /Thank you for\s+signing up to donate books/
      assert_select 'p', /You have pledged to donate 3 books/
      assert_select 'p', /Right now there are #{Request.not_granted.count} students waiting/
      assert_select 'a', /Read their appeals/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "fulfill donations" do
    user = create :volunteer
    reminder = Reminders::FulfillDonations.new_for_entity user
    count = Donation.needs_fulfillment.count

    verify_reminder reminder, "1 book is waiting to be fulfilled on Free Objectivist Books" do
      assert_select 'p', /Hi Volunteer \d+,/
      assert_select 'p', /there is currently 1 donation waiting/i
      assert_select 'p', /see and send it/i
      assert_select 'a', /help out/i
    end
  end

  test "fulfill donations multiple outstanding" do
    user = create :volunteer
    reminder = Reminders::FulfillDonations.new_for_entity user
    create :donation, :paid
    count = Donation.needs_fulfillment.count

    verify_reminder reminder, "#{count} books are waiting to be fulfilled on Free Objectivist Books" do
      assert_select 'p', /Hi Volunteer \d+,/
      assert_select 'p', /there are currently #{count} donations waiting/i
      assert_select 'p', /see and send them/i
      assert_select 'a', /help out/i
    end
  end

  test "fulfill donations for volunteer with recent fulfillments" do
    user = create :volunteer
    create_list :fulfillment, 2, user: user
    Timecop.travel 4.days

    reminder = Reminders::FulfillDonations.new_for_entity user
    count = Donation.needs_fulfillment.count

    verify_reminder reminder do
      assert_select 'p', /sent 2 books/
    end
  end

  test "renew request" do
    request = create :request, :renewable
    reminder = Reminders::RenewRequest.new_for_entity request

    verify_reminder reminder, /Do you still want Book \d+\?/ do
      assert_select 'p', /Hi Student \d+,/
      assert_select 'p', /requested a copy of Book \d+/
      assert_select 'p', /on [A-Z][a-z]+ \d+ \(about 1 month ago\)/
      assert_select 'a', /Renew your request for Book \d+/
      assert_select 'a', /cancel/
      assert_select 'p', /hear back from you by [A-Z][a-z]+ \d+,/
    end
  end

  test "renew request for very old request doesn't give cancel date" do
    request = create :request, :autocancelable
    reminder = Reminders::RenewRequest.new_for_entity request

    verify_reminder reminder do
      assert_select 'p', /hear back from you soon,/
    end
  end

  test "send books for donor with one outstanding donation" do
    donation = create :donation

    reminder = Reminders::SendBooks.new_for_entity donation.user

    verify_reminder reminder, /Have you sent Book \d+ to Student \d+ yet?/ do
      assert_select 'p', /Hi Donor \d+,/
      assert_select 'p', /said you would donate Book \d+ to Student \d+ in Anytown, USA/
      assert_select 'p', /please send it soon/
      assert_select 'p', /we can send\s+this book\s+on your behalf for a contribution of \$10/
      assert_select 'p', /take care of your donations/
      assert_select 'a', /outstanding donations/
      assert_select 'p', /notify the student that the book is on its way/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "send books for donor with multiple outstanding donations" do
    user = create :donor
    create_list :donation, 2, user: user

    reminder = Reminders::SendBooks.new_for_entity user

    verify_reminder reminder, "Have you sent your 2 Objectivist books to students yet?" do
      assert_select 'p', /Hi Donor \d+,/
      assert_select 'p', /said you would donate these books/
      assert_select 'li', text: /Book \d+ to Student \d+ in Anytown, USA/, count: 2
      assert_select 'p', /please send them soon/
      assert_select 'p', /we can send\s+these books\s+on your behalf for a contribution of \$20/
      assert_select 'p', /take care of your donations/
      assert_select 'a', /outstanding donations/
      assert_select 'p', /notify the students that the books are on their way/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "send books for donor with one ineligible outstanding donation" do
    donation = create :donation_for_request_not_amazon

    reminder = Reminders::SendBooks.new_for_entity donation.user

    verify_reminder reminder, /Have you sent Book \d+ to Student \d+ yet?/ do
      assert_select 'p', /Hi Donor \d+,/
      assert_select 'p', /said you would donate Book \d+ to Student \d+ in Anytown, USA/
      assert_select 'p', /please send it soon/
      assert_select 'p', text: /on your behalf/, count: 0
      assert_select 'p', /find your outstanding donations/
      assert_select 'a', /outstanding donations/
      assert_select 'p', /notify the student that the book is on its way/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "send books for donor with multiple outstanding donations, all ineligible" do
    user = create :donor
    create_list :donation_for_request_not_amazon, 2, user: user

    reminder = Reminders::SendBooks.new_for_entity user

    verify_reminder reminder, "Have you sent your 2 Objectivist books to students yet?" do
      assert_select 'p', /Hi Donor \d+,/
      assert_select 'p', /said you would donate these books/
      assert_select 'li', text: /Book \d+ to Student \d+ in Anytown, USA/, count: 2
      assert_select 'p', /please send them soon/
      assert_select 'p', text: /on your behalf/, count: 0
      assert_select 'p', /find your outstanding donations/
      assert_select 'a', /outstanding donations/
      assert_select 'p', /notify the students that the books are on their way/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "send books for donor with multiple outstanding donations, one eligible" do
    user = create :donor
    create :donation, user: user
    create :donation_for_request_not_amazon, user: user

    reminder = Reminders::SendBooks.new_for_entity user

    verify_reminder reminder, "Have you sent your 2 Objectivist books to students yet?" do
      assert_select 'p', /Hi Donor \d+,/
      assert_select 'p', /said you would donate these books/
      assert_select 'li', text: /Book \d+ to Student \d+ in Anytown, USA/, count: 2
      assert_select 'p', /please send them soon/
      assert_select 'p', /we can send\s+one of these books\s+on your behalf for a contribution of \$10/
      assert_select 'p', /take care of your donations/
      assert_select 'a', /outstanding donations/
      assert_select 'p', /notify the students that the books are on their way/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "send books for donor with multiple outstanding donations, multiple but not all eligible" do
    user = create :donor
    create_list :donation, 2, user: user
    create :donation_for_request_not_amazon, user: user

    reminder = Reminders::SendBooks.new_for_entity user

    verify_reminder reminder, "Have you sent your 3 Objectivist books to students yet?" do
      assert_select 'p', /Hi Donor \d+,/
      assert_select 'p', /said you would donate these books/
      assert_select 'li', text: /Book \d+ to Student \d+ in Anytown, USA/, count: 3
      assert_select 'p', /please send them soon/
      assert_select 'p', /we can send\s+up to 2 of these books\s+on your behalf for a contribution of \$20/
      assert_select 'p', /take care of your donations/
      assert_select 'a', /outstanding donations/
      assert_select 'p', /notify the students that the books are on their way/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "confirm receipt unsent" do
    reminder = Reminders::ConfirmReceiptUnsent.new_for_entity @quentin_donation_unsent

    verify_reminder reminder, "Have you received The Fountainhead yet?" do
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

    verify_reminder reminder, "Have you received The Virtue of Selfishness yet?" do
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

    reminder = Reminders::ConfirmReceipt.new_for_entity @frisco_donation

    verify_reminder reminder, "Have you received Objectivism: The Philosophy of Ayn Rand yet?" do
      assert_select 'p', /Hi Francisco/
      assert_select 'p', /Have you received Objectivism: The Philosophy of Ayn Rand/
      assert_select 'p', /Kira Argounova has sent you this book/
      assert_select 'a', /I have received Objectivism/
      assert_select 'p', /Thanks,\nFree Objectivist Books/
    end
  end

  test "read books" do
    donation = create :donation
    donation.update_status! 'received'
    Timecop.travel 5.weeks

    reminder = Reminders::ReadBooks.new_for_entity donation

    verify_reminder reminder, /Have you finished reading Book \d+\?/ do
      assert_select 'p', /Hi Student \d+/
      assert_select 'p', /You received Book \d+ on [A-Z][a-z]{2} \d+ \(about 1 month ago\)/
      assert_select 'a', /Yes, I have finished reading Book \d+/
      assert_select 'p', /your donor, Donor \d+/
    end
  end

  test "fix flag" do
    flag = create :flag
    Timecop.travel 1.week

    reminder = Reminders::FixFlag.new_for_entity flag

    verify_reminder reminder, /Problem with your shipping info for Book \d+/ do
      assert_select 'p', /Hi Student \d+,/
      assert_select 'p', /need your response to send your\s+copy of Book \d+/
      assert_select 'p', /Donor \d+ \(the donor\) says: "Please correct your address"/
      assert_select 'p', text: /need your address/, count: 0
      assert_select 'a', /Respond to get your book/
    end
  end

  test "fix flag for missing address" do
    donation = create :donation_for_request_no_address
    Timecop.travel 1.week

    reminder = Reminders::FixFlag.new_for_entity donation.flag

    verify_reminder reminder, /We need your shipping info for Book \d+/ do
      assert_select 'p', /Hi Student \d+,/
      assert_select 'p', /need your address to send your copy of Book \d+/
      assert_select 'p', text: /problem with your shipping info/, count: 0
      assert_select 'p', text: /says:/, count: 0
      assert_select 'a', /Respond to get your book/
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
