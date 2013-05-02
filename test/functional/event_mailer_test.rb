require 'test_helper'

class EventMailerTest < ActionMailer::TestCase
  def verify_mail_body(mail, &block)
    ActionMailer::Base.deliveries = []
    assert_equal ["jason@rationalegoist.com"], mail.from
    assert mail.body.encoded.present?, "mail is blank"
    mail.deliver
    assert_select_email &block
  end

  test "grant" do
    mail = EventMailer.mail_for_event events(:hugh_grants_quentin), @quentin
    assert_equal "We found a donor to send you The Virtue of Selfishness!", mail.subject
    assert_equal [@quentin.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Quentin/
      assert_select 'p', /found a donor to send you The Virtue of Selfishness/
      assert_select 'p', /Hugh Akston in Boston, MA/
      @quentin.address.split("\n").each do |line|
        assert_select 'p', /#{line}/
      end
      assert_select 'a', /update/i
    end
  end

  test "grant no address" do
    mail = EventMailer.mail_for_event events(:hugh_grants_dagny), @dagny
    assert_equal "We found a donor to send you Capitalism: The Unknown Ideal!", mail.subject
    assert_equal [@dagny.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Dagny/
      assert_select 'p', /found a donor to send you Capitalism: The Unknown Ideal/
      assert_select 'p', /Hugh Akston in Boston, MA/
      assert_select 'a', /add your address/i
    end
  end

  test "flag" do
    donation = create :donation
    event = donation.flag!

    mail = EventMailer.mail_for_event event, donation.student
    assert_match /Problem with your shipping info for Book \d+/, mail.subject
    assert_equal [donation.student.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Student \d+,/
      assert_select 'p', /Donor \d+ \(the donor\) says: "Fix this"/
      assert_select 'a', /Respond to get your copy of Book \d+/
    end
  end

  test "flag by fulfiller, to student" do
    fulfillment = create :fulfillment
    event = fulfillment.donation.flag!

    mail = EventMailer.mail_for_event event, fulfillment.student
    assert_match /Problem with your shipping info for Book \d+/, mail.subject
    assert_equal [fulfillment.student.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Student \d+,/
      assert_select 'p', /Volunteer \d+ \(Free Objectivist Books volunteer\) says: "Fix this"/
      assert_select 'a', /Respond to get your copy of Book \d+/
    end
  end

  test "flag by fulfiller, to donor" do
    fulfillment = create :fulfillment
    event = fulfillment.donation.flag!

    mail = EventMailer.mail_for_event event, fulfillment.donor
    assert_match /Delay in sending Book \d+ to Student \d+/, mail.subject
    assert_equal [fulfillment.donor.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Donor \d+,/
      assert_select 'p', /FYI/
      assert_select 'p', /your donation of Book \d+ to Student \d+/
      assert_select 'p', /Volunteer \d+ \(Free Objectivist Books volunteer\) has flagged/
      assert_select 'p', /We'll follow up with Student \d+/
      assert_select 'a', text: /Respond/, count: 0
    end
  end

  test "add address" do
    donation = create :donation_for_request_no_address
    event = donation.flag.fix! address: "123 Somewhere\nAnytown, USA", fix_message: "There you go"

    mail = EventMailer.mail_for_event event, donation.user
    assert_match /Student \d+ added a shipping address for Book \d+/, mail.subject
    assert_equal [donation.user.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Donor \d+,/
      assert_select 'p', /You flagged Student \d+.+s request/
      assert_select 'p', /They have added a shipping address./
      assert_select 'p', /They said: "There you go"/
      assert_select 'p', /Please send Book \d+ to/
      assert_select 'p', /123 Somewhere/
      assert_select 'p', /Anytown, USA/
      assert_select 'a', /Confirm/
    end
  end

  test "fix with message" do
    flag = create :flag
    event = flag.fix! fix_message: "This is correct"

    mail = EventMailer.mail_for_event event, flag.donor
    assert_match /Student \d+ responded to your flag for Book \d+/, mail.subject
    assert_equal [flag.donor.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Donor \d+/
      assert_select 'p', /You flagged Student \d+'s request/
      assert_select 'p', text: /They have /, count: 0
      assert_select 'p', /They said: "This is correct"/
      assert_select 'p', /Please send Book \d+ to/
      flag.address.split("\n").each do |line|
        assert_select 'p', /#{line}/
      end
      assert_select 'a', /Confirm/
    end
  end

  test "message" do
    mail = EventMailer.mail_for_event events(:hugh_messages_quentin), @quentin
    assert_equal "Hugh Akston sent you a message about The Virtue of Selfishness", mail.subject
    assert_equal [@quentin.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Quentin/
      assert_select 'p', /Hugh Akston sent you a\s+message/
      assert_select 'p', /"Thanks! I will send you the book"/
      assert_select 'a', /Reply to Hugh/
      assert_select 'a', /Full details for this request/
    end
  end

  test "message to multiple recipients" do
    fulfillment = create :fulfillment
    event = fulfillment.donation.message_events.build user: fulfillment.student, message: "Hello!"

    mail = EventMailer.mail_for_event event, fulfillment.donor
    assert_match /Student \d+ sent you and Volunteer \d+ a message about Book \d+/, mail.subject
    assert_equal [fulfillment.donor.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Donor \d+/
      assert_select 'p', /Student \d+ sent you and Volunteer \d+ a\s+message/
      assert_select 'p', /"Hello!"/
      assert_select 'a', /Reply to Student \d+/
      assert_select 'a', /Full details for this request/
    end
  end

  test "sent" do
    mail = EventMailer.mail_for_event events(:hugh_updates_quentin), @quentin
    assert_equal "The Virtue of Selfishness is on its way", mail.subject
    assert_equal [@quentin.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Quentin/
      assert_select 'p', /Hugh Akston has sent you The Virtue of Selfishness!/
      assert_select 'a', /Let us know/
      assert_select 'p', /Happy reading,/
    end
  end

  test "sent by fulfiller, to student" do
    @frisco_donation.fulfill @kira
    event = @frisco_donation.update_status({status: "sent"}, @kira)
    @frisco_donation.save!

    mail = EventMailer.mail_for_event event, @frisco
    assert_equal "Objectivism: The Philosophy of Ayn Rand is on its way", mail.subject
    assert_equal [@frisco.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Francisco/
      assert_select 'p', /Objectivism: The Philosophy of Ayn Rand is on its way!/
      assert_select 'p', /Henry Cameron donated/
      assert_select 'p', /Kira Argounova has sent/
      assert_select 'a', /Let us know/
      assert_select 'p', /Happy reading,/
    end
  end

  test "sent by fulfiller, cc to donor" do
    @frisco_donation.fulfill @kira
    event = @frisco_donation.update_status({status: "sent"}, @kira)
    @frisco_donation.save!

    mail = EventMailer.mail_for_event event, @cameron
    assert_equal "Objectivism: The Philosophy of Ayn Rand is on its way to Francisco d'Anconia", mail.subject
    assert_equal [@cameron.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Henry/
      assert_select 'p', /Objectivism: The Philosophy of Ayn Rand, which you donated to Francisco d&#x27;Anconia,/
      assert_select 'p', /Volunteer Kira Argounova has sent/
      assert_select 'p', /confirmed that Francisco d&#x27;Anconia has received/
      assert_select 'p', /Thanks,/
    end
  end

  test "received" do
    mail = EventMailer.mail_for_event events(:hank_updates_cameron), @cameron
    assert_equal "Hank Rearden has received The Fountainhead", mail.subject
    assert_equal [@cameron.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Henry/
      assert_select 'p', /Hank Rearden has received The Fountainhead/
      assert_select 'p', /They said: "I got the book. Thank you!"/
      assert_select 'a', /Reply to Hank Rearden/
      assert_select 'a', /Find more students/
      assert_select 'p', /Thanks,/
    end
  end

  test "received with no message" do
    event = events(:hank_updates_cameron)
    event.update_attributes message: ""

    mail = EventMailer.mail_for_event event, @cameron
    assert_equal "Hank Rearden has received The Fountainhead", mail.subject
    assert_equal [@cameron.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Henry/
      assert_select 'p', /Hank Rearden has received The Fountainhead/
      assert_select 'p', text: /They said/, count: 0
      assert_select 'p', /Thank you for being a donor/
      assert_select 'a', text: /Reply to Hank Rearden/, count: 0
      assert_select 'a', /Find more students/
      assert_select 'p', /Thanks,/
    end
  end

  test "received, to fulfiller" do
    @frisco_donation.fulfill @kira
    event = @frisco_donation.update_status status: "received"
    @frisco_donation.save!

    mail = EventMailer.mail_for_event event, @kira
    assert_equal "Francisco d'Anconia has received Objectivism: The Philosophy of Ayn Rand", mail.subject
    assert_equal [@kira.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Kira/
      assert_select 'p', /Francisco d&#x27;Anconia has received Objectivism: The Philosophy of Ayn Rand/
      assert_select 'p', /Thank you for being a volunteer for/
      assert_select 'a', text: /Find more students/, count: 0
      assert_select 'p', /Thanks,/
    end
  end

  test "thank" do
    mail = EventMailer.mail_for_event events(:quentin_thanks_hugh), @hugh
    assert_equal "Quentin Daniels sent you a thank-you note for The Virtue of Selfishness", mail.subject
    assert_equal [@hugh.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Hugh/
      assert_select 'p', /Quentin Daniels sent you a\s+thank-you note for The Virtue of Selfishness/
      assert_select 'p', /"Thanks! I am looking forward to reading this"/
      assert_select 'a', /Reply to Quentin/
    end
  end

  test "read" do
    mail = EventMailer.mail_for_event events(:quentin_updates_cameron), @cameron
    assert_equal "Quentin Daniels has read Atlas Shrugged", mail.subject
    assert_equal [@cameron.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Henry/
      assert_select 'p', /Quentin Daniels has finished reading Atlas Shrugged! Here's what they thought/
      assert_select 'p', /"It was great! Especially the physics."/
      assert_select 'a', /Find more students/
      assert_select 'p', /Thanks,/
    end
  end

  test "read no review" do
    event = @hank_donation_received.update_status status: "read"
    mail = EventMailer.mail_for_event event, @cameron
    assert_equal "Hank Rearden has read The Fountainhead", mail.subject
    assert_equal [@cameron.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Henry/
      assert_select 'p', /Hank Rearden has finished reading The Fountainhead!/
      assert_select 'p', text: /Here's what they thought/, count: 0
      assert_select 'a', /Find more students/
      assert_select 'p', /Thanks,/
    end
  end

  test "read, to fulfiller" do
    @frisco_donation.fulfill @kira
    event = @frisco_donation.update_status status: "read"
    @frisco_donation.save!

    mail = EventMailer.mail_for_event event, @kira
    assert_equal "Francisco d'Anconia has read Objectivism: The Philosophy of Ayn Rand", mail.subject
    assert_equal [@kira.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Kira/
      assert_select 'p', /Francisco d&#x27;Anconia has finished reading Objectivism: The Philosophy of Ayn Rand/
      assert_select 'p', /Thank you for being a volunteer for/
      assert_select 'a', text: /Find more students/, count: 0
      assert_select 'p', /Thanks,/
    end
  end

  test "cancel donation" do
    mail = EventMailer.mail_for_event events(:stadler_cancels_quentin), @quentin
    assert_equal "We need to find you a new donor for Objectivism: The Philosophy of Ayn Rand", mail.subject
    assert_equal [@quentin.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Quentin/
      assert_select 'p', /Robert Stadler has canceled their donation of Objectivism: The Philosophy of Ayn Rand/
      assert_select 'p', /Robert Stadler said: "Sorry! I can&#x27;t give you this after all"/
      assert_select 'p', /Yours,\nFree Objectivist Books/
    end
  end

  test "cancel donation not received" do
    donation = create :donation
    Timecop.travel 1.month
    event = donation.cancel! donation.student, detail: 'not_received'

    mail = EventMailer.mail_for_event event, donation.user
    assert_match /Your donation of Book \d+ to Student \d+ has been canceled/, mail.subject
    assert_equal [donation.user.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Donor \d+,/
      assert_select 'p', /Student \d+ says they have not yet received Book \d+/
      assert_select 'p', /on [A-Z][a-z]{2} \d{1,2} \(about 1 month ago\)/
      assert_select 'p', /Yours,/
    end
  end

  test "cancel request" do
    donation = create :donation
    event = donation.request.cancel!

    mail = EventMailer.mail_for_event event, donation.user
    assert_match /Student \d+ has canceled their request for Book \d+/, mail.subject
    assert_equal [donation.user.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Donor \d+,/
      assert_select 'p', /Student \d+ has canceled their request for Book \d+/
      assert_select 'p', /They said: "Do not need it anymore"/
      assert_select 'a', /Find more students/
      assert_select 'p', /Thanks,/
    end
  end

  test "autocancel" do
    Timecop.freeze "2013-03-28 12:00"
    created_at = Time.parse "2013-01-25 12:00"
    request = create :request, created_at: created_at, open_at: created_at
    event = request.autocancel_if_needed!

    mail = EventMailer.mail_for_event event, request.user
    assert_match /We've canceled your request for Book \d+/, mail.subject
    assert_equal [request.user.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Student \d+,/
      assert_select 'p', /requested a copy of Book \d+/
      assert_select 'p', /on Jan 25 \(2 months ago\)/
      assert_select 'a', /Reopen your request for Book \d+/
      assert_select 'a', /new book request/
    end
  end

  test "autocancel before Apr 10 mentions new donor drive" do
    Timecop.freeze "2013-04-08"
    request = create :request, :autocancelable
    event = request.autocancel_if_needed!

    mail = EventMailer.mail_for_event event, request.user

    verify_mail_body mail do
      assert_select 'p', /new donor drive/
    end
  end

  test "autocancel after Apr 10 doesn't mention new donor drive" do
    Timecop.freeze "2013-04-12"
    request = create :request, :autocancelable
    event = request.autocancel_if_needed!

    mail = EventMailer.mail_for_event event, request.user

    verify_mail_body mail do
      assert_select 'p', text: /new donor drive/, count: 0
    end
  end
end
