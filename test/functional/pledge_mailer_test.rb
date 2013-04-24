require 'test_helper'

class PledgeMailerTest < ActionMailer::TestCase
  def verify_pledge_rotation_mail(pledge, subject, &block)
    Timecop.travel 1.month
    pledge.ended = true
    ActionMailer::Base.deliveries = []

    mail = PledgeMailer.pledge_rotation pledge
    assert_equal [pledge.user.email], mail.to
    case subject
    when String then assert_equal subject, mail.subject
    when Regexp then assert_match subject, mail.subject
    end

    assert mail.body.encoded.present?, "mail is blank"
    mail.deliver
    assert_select_email do
      assert_select 'p', /Hi Donor \d+,/
      yield block
      assert_select 'a[href=?]', Rails.application.routes.url_helpers.new_pledge_url
      assert_select 'p', /There are \d+ students/
      assert_select 'p', /Thanks for being a donor,/
    end
  end

  test "pledge rotation for empty pledge" do
    pledge = create :pledge

    verify_pledge_rotation_mail pledge, "Your pledge on Free Objectivist Books is up" do
      assert_select 'p', /On [A-Z][a-z]{2} \d+ you pledged to donate 5 books/
      assert_select 'p', /didn.+t .* donate any/
      assert_select 'p', /pledge is up/
      assert_select 'p', /can always make a new/
    end
  end

  test "pledge rotation for partially fulfilled pledge" do
    pledge = create :pledge
    create :donation, user: pledge.user

    verify_pledge_rotation_mail pledge, "Your pledge on Free Objectivist Books is up" do
      assert_select 'p', /On [A-Z][a-z]{2} \d+ you pledged to donate 5 books/
      assert_select 'p', /donated 1 book towards this pledge/
      assert_select 'p', /pledge is up/
      assert_select 'p', /can always make a new/
    end
  end

  test "pledge rotation for fulfilled pledge" do
    pledge = create :pledge, quantity: 1
    create :donation, user: pledge.user

    verify_pledge_rotation_mail pledge, "Thank you for fulfilling your pledge of 1 book on Free Objectivist Books" do
      assert_select 'p', /On [A-Z][a-z]{2} \d+ you pledged to donate 1 book/
      assert_select 'p', /fulfilled this pledge/
      assert_select 'p', /going strong/
    end
  end

  test "pledge rotation for exceeded pledge" do
    pledge = create :pledge, quantity: 2
    create_list :donation, 3, user: pledge.user

    verify_pledge_rotation_mail pledge, "You exceeded your pledge of 2 books on Free Objectivist Books!" do
      assert_select 'p', /On [A-Z][a-z]{2} \d+ you pledged to donate 2 books/
      assert_select 'p', /exceeded this pledge/
      assert_select 'p', /going strong/
    end
  end
end
