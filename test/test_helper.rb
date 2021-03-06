ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def params(params = {})
    params
  end

  def session_for(user)
    user ? {user_id: user.id} : {}
  end

  def user_agent_for(browser)
    case browser
    when :chrome then "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.95 Safari/537.11"
    when :safari then "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/536.26.17 (KHTML, like Gecko) Version/6.0.2 Safari/536.26.17"
    when :firefox then "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:8.0.1) Gecko/20100101 Firefox/8.0.1"
    end
  end

  def setup
    @atlas = books :atlas
    @fountainhead = books :fountainhead
    @vos = books :vos
    @cui = books :cui
    @opar = books :opar

    @howard = users :howard
    @quentin = users :quentin
    @dagny = users :dagny
    @hank = users :hank
    @frisco = users :frisco
    @hugh = users :hugh
    @cameron = users :cameron
    @stadler = users :stadler
    @kira = users :kira
    @irina = users :irina

    @hugh_pledge = pledges :hugh_pledge
    @cameron_pledge = pledges :cameron_pledge
    @stadler_pledge = pledges :stadler_pledge

    @howard_request = requests :howard_wants_atlas
    @quentin_request = requests :quentin_wants_vos
    @dagny_request = requests :dagny_wants_cui
    @hank_request = requests :hank_wants_atlas
    @frisco_request = requests :frisco_wants_opar
    @quentin_request_unsent = requests :quentin_wants_fountainhead
    @hank_request_received = requests :hank_wants_fountainhead
    @quentin_request_open = requests :quentin_wants_opar
    @quentin_request_read = requests :quentin_wants_atlas
    @dagny_request_canceled = requests :dagny_wants_atlas
    @howard_request_canceled = requests :howard_wants_fountainhead

    @quentin_donation = donations :hugh_grants_quentin_wants_vos
    @dagny_donation = donations :hugh_grants_dagny_wants_cui
    @hank_donation = donations :cameron_grants_hank_wants_atlas
    @frisco_donation = donations :cameron_grants_frisco_wants_opar
    @quentin_donation_unsent = donations :hugh_grants_quentin_wants_fountainhead
    @hank_donation_received = donations :cameron_grants_hank_wants_fountainhead
    @quentin_donation_read = donations :cameron_grants_quentin_wants_atlas
    @dagny_donation_canceled = donations :hugh_grants_dagny_wants_atlas

    @quentin_review = reviews :quentin_reviews_atlas
    @stadler_review = reviews :stadler_reviews_atlas

    @email_referral = referrals :sfl_email
    @fb_referral = referrals :sfl_fb

    @hugh_reminder = reminders :hugh_fulfill_pledge
    @hugh_send_books_reminder = reminders :hugh_send_books
    @cameron_reminder = reminders :cameron_send_books

    ActionMailer::Base.deliveries = []
  end

  def teardown
    Timecop.return
  end

  def decode_json_response
    ActiveSupport::JSON.decode @response.body
  end

  def verify_login_page
    assert_response :unauthorized
    assert_select 'h1', 'Log in'
  end

  def verify_wrong_login_page
    assert_response :forbidden
    assert_select 'h1', 'Wrong login?'
  end

  def verify_link(text, present = true)
    if present
      assert_select 'a', /#{text}/i, "expected link containing '#{text}'"
    else
      assert_select 'a', {text: /#{text}/i, count: 0}, "found link containing '#{text}'"
    end
  end

  def verify_event(entity, type, options = {})
    entity.reload
    event = entity.events.reorder(:id).last
    assert_not_nil event, "no events for #{entity.inspect}"
    assert_equal type, event.type
    options.keys.each do |key|
      assert_equal options[key], event.send(key), "verify_event: #{key} didn't match"
    end
  end

  def verify_scope(model_class, scope)
    models = model_class.send scope
    assert models.any?, "no #{model_class.name.pluralize} matched scope #{scope}"
    models.each do |model|
      matches = yield model
      assert matches, "#{model_class.name} #{model.id} doesn't match scope #{scope}: #{model.inspect}"
    end
  end

  def assert_open_at_is_recent(request)
    assert_not_nil request.open_at
    time_since_open_at = Time.since(request.open_at)
    assert time_since_open_at < 2, "time since open_at: #{time_since_open_at}"
  end
end

class ActionMailer::TestCase
  include ActionDispatch::Assertions::SelectorAssertions

  def url_helpers
    Rails.application.routes.url_helpers
  end
end

class User
  def expired_auth_token
    auth_token (AUTH_TOKEN_EXPIRATION + 1.hour).ago
  end

  def cancel_pledge!
    current_pledge.cancel! if current_pledge
  end
end

class Request
  def grant!(donor = nil)
    donor ||= FactoryGirl.create :donor
    event = grant donor
    save!
    event.save!
    reload
    donation
  end

  def cancel!
    params = {event: {message: "Do not need it anymore"}}
    event = cancel params
    save!
    donation.save! if donation
    event.save! if event
    event
  end
end

class Pledge
  def cancel!
    params = {event: {message: ""}}
    event = cancel params
    save!
    event.save! if event
    event
  end
end

class Donation
  def update_status!(status, user = nil, message = nil, time = nil)
    time ||= Time.now
    params = {status: status}
    params[:event] = {message: message} if message
    event = update_status params, user, time
    save!
    event.save! if event
    event
  end

  def send!(user = nil, time = nil)
    user ||= sender
    update_status! 'sent', user, nil, time
  end

  def receive!(user = nil, time = nil)
    user ||= student
    update_status! 'received', user, "Thanks!", time
  end

  def read!
    update_status! 'read', student, "It was great!"
  end

  def flag!(user = nil)
    user ||= sender
    params = {message: "Fix this", type: 'shipping_info'}
    event = add_flag params, user
    save!
    event.save! if event
    reload
    event
  end

  def cancel!(user, event_params = {})
    event_params[:message] ||= "Sorry"
    event = cancel({event: event_params}, user)
    save!
    event.save! if event
    event
  end

  def message!(user, attributes = {})
    attributes[:message] ||= "Hello"
    Event.create! attributes.merge(user: user, donation: self, type: 'message')
  end

  def thank!(message = "Thanks!")
    message! student, message: message, is_thanks: true, public: false
  end

  def fulfill!(user = nil)
    user ||= FactoryGirl.create :volunteer
    fulfill user
  end
end

class Flag
  def fix!(attributes = {})
    attributes[:fix_message] ||= "Fixed"
    event = fix attributes
    save!
    donation.save!
    event.save!
    event.reload
    event
  end
end
