require 'test_helper'

class EventMailerTest < ActionMailer::TestCase
  def verify_mail_body(mail, &block)
    assert_equal ["jason@rationalegoist.com"], mail.from
    assert mail.body.encoded.present?, "mail is blank"
    mail.deliver
    assert_select_email &block
  end

  test "grant" do
    mail = EventMailer.mail_for_event events(:hugh_grants_quentin)
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
    mail = EventMailer.mail_for_event events(:hugh_grants_dagny)
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
    mail = EventMailer.mail_for_event events(:hugh_flags_dagny)
    assert_equal "Problem with your shipping info for Capitalism: The Unknown Ideal", mail.subject
    assert_equal [@dagny.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Dagny/
      assert_select 'p', 'Your donor (Hugh Akston) says: "Please add your full name and address"'
      assert_select 'a', /Respond to Hugh Akston to get your copy of Capitalism: The Unknown Ideal/
    end
  end

  test "add name" do
    mail = EventMailer.mail_for_event events(:quentin_adds_name)
    assert_equal "Quentin Daniels added their full name for The Virtue of Selfishness", mail.subject
    assert_equal [@hugh.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Hugh/
      assert_select 'p', /You flagged Quentin Daniels's request/
      assert_select 'p', /They have added their full name./
      assert_select 'p', text: /said/, count: 0
      assert_select 'p', /Please send The Virtue of Selfishness to/
      @quentin.address.split("\n").each do |line|
        assert_select 'p', /#{line}/
      end
      assert_select 'a', /Confirm/
    end
  end

  test "add address" do
    mail = EventMailer.mail_for_event events(:quentin_adds_address)
    assert_equal "Quentin Daniels added a shipping address for The Virtue of Selfishness", mail.subject
    assert_equal [@hugh.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Hugh/
      assert_select 'p', /You flagged Quentin Daniels's request/
      assert_select 'p', /They have added a shipping address./
      assert_select 'p', /They said: "There you go"/
      assert_select 'p', /Please send The Virtue of Selfishness to/
      @quentin.address.split("\n").each do |line|
        assert_select 'p', /#{line}/
      end
      assert_select 'a', /Confirm/
    end
  end

  test "fix with message" do
    mail = EventMailer.mail_for_event events(:quentin_fixes)
    assert_equal "Quentin Daniels responded to your flag for The Virtue of Selfishness", mail.subject
    assert_equal [@hugh.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Hugh/
      assert_select 'p', /You flagged Quentin Daniels's request/
      assert_select 'p', text: /They have /, count: 0
      assert_select 'p', /They said: "This is correct"/
      assert_select 'p', /Please send The Virtue of Selfishness to/
      @quentin.address.split("\n").each do |line|
        assert_select 'p', /#{line}/
      end
      assert_select 'a', /Confirm/
    end
  end

  test "message" do
    mail = EventMailer.mail_for_event events(:hugh_messages_quentin)
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

  test "sent" do
    mail = EventMailer.mail_for_event events(:hugh_updates_quentin)
    assert_equal "Hugh Akston has sent The Virtue of Selfishness", mail.subject
    assert_equal [@quentin.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Quentin/
      assert_select 'p', /Hugh Akston has sent you The Virtue of Selfishness!/
      assert_select 'a', /Let Hugh Akston know/
      assert_select 'p', /Happy reading,/
    end
  end

  test "received" do
    mail = EventMailer.mail_for_event events(:hank_updates_cameron)
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

    mail = EventMailer.mail_for_event event
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

  test "thank" do
    mail = EventMailer.mail_for_event events(:quentin_thanks_hugh)
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
    mail = EventMailer.mail_for_event events(:quentin_updates_cameron)
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
    mail = EventMailer.mail_for_event event
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

  test "cancel donation" do
    mail = EventMailer.mail_for_event events(:stadler_cancels_quentin)
    assert_equal "We need to find you a new donor for Objectivism: The Philosophy of Ayn Rand", mail.subject
    assert_equal [@quentin.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Quentin/
      assert_select 'p', /Robert Stadler has canceled their donation of Objectivism: The Philosophy of Ayn Rand/
      assert_select 'p', /Robert Stadler said: "Sorry! I can't give you this after all"/
      assert_select 'p', /Yours,\nFree Objectivist Books/
    end
  end

  test "cancel donation not received" do
    mail = EventMailer.mail_for_event events(:howard_cancels_stadler)
    assert_equal "Your donation of Atlas Shrugged to Howard Roark has been canceled", mail.subject
    assert_equal [@stadler.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Robert/
      assert_select 'p', /Howard Roark says they have not yet received Atlas Shrugged/
      assert_select 'p', /you agreed to donate to them on\s+Jan 20 \(.* ago\)/
      assert_select 'p', /Yours,/
    end
  end

  test "cancel request" do
    mail = EventMailer.mail_for_event events(:dagny_cancels)
    assert_equal "Dagny has canceled their request for Atlas Shrugged", mail.subject
    assert_equal [@hugh.email], mail.to

    verify_mail_body mail do
      assert_select 'p', /Hi Hugh/
      assert_select 'p', /Dagny has canceled their request for Atlas Shrugged/
      assert_select 'p', /They said: "I don't need this anymore"/
      assert_select 'a', /Find more students/
      assert_select 'p', /Thanks,/
    end
  end
end
