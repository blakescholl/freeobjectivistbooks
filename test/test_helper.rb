ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
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

  def setup
    @howard = users :howard
    @quentin = users :quentin
    @dagny = users :dagny
    @hank = users :hank

    @hugh = users :hugh
    @cameron = users :cameron
    @stadler = users :stadler

    @hugh_pledge = pledges :hugh_pledge
    @cameron_pledge = pledges :cameron_pledge
    @stadler_pledge = pledges :stadler_pledge

    @howard_request = requests :howard_wants_atlas
    @quentin_request = requests :quentin_wants_vos
    @dagny_request = requests :dagny_wants_cui
    @hank_request = requests :hank_wants_atlas
    @quentin_request_unsent = requests :quentin_wants_fountainhead
    @hank_request_received = requests :hank_wants_fountainhead
    @quentin_request_open = requests :quentin_wants_opar
    @quentin_request_read = requests :quentin_wants_atlas
    @dagny_request_canceled = requests :dagny_wants_atlas
    @howard_request_canceled = requests :howard_wants_fountainhead

    @quentin_donation = donations :hugh_grants_quentin_wants_vos
    @dagny_donation = donations :hugh_grants_dagny_wants_cui
    @hank_donation = donations :cameron_grants_hank_wants_atlas
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

  def admin_auth
    authenticate_with_http_digest "admin", "password", "Admin"
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
    event = entity.events.last
    assert_not_nil event, "no events for #{entity.inspect}"
    assert_equal type, event.type
    options.keys.each do |key|
      assert_equal options[key], event.send(key), "verify_event: #{key} didn't match"
    end
  end

  def verify_scope(model_class, scope)
    models = model_class.send scope
    assert models.any?, "no #{model_class.name.pluralize} matched scope #{scope}"
    models.each {|model| assert (yield model), "#{model_class.name} #{model.id} doesn't match scope #{scope}"}
  end

  def assert_open_at_is_recent(request)
    assert_not_nil request.open_at
    time_since_open_at = Time.since(request.open_at)
    assert time_since_open_at < 1, "time since open_at: #{time_since_open_at}"
  end
end

# from https://gist.github.com/1282275
class ActionController::TestCase
  require 'digest/md5'

  def authenticate_with_http_digest(user, password, realm)
    ActionController::Base.class_eval { include ActionController::Testing }

    @controller.instance_eval %Q(
      alias real_process_with_new_base_test process_with_new_base_test

      def process_with_new_base_test(request, response)
        credentials = {
      	  :uri => request.url,
      	  :realm => "#{realm}",
      	  :username => "#{user}",
      	  :nonce => ActionController::HttpAuthentication::Digest.nonce(request.env['action_dispatch.secret_token']),
      	  :opaque => ActionController::HttpAuthentication::Digest.opaque(request.env['action_dispatch.secret_token'])
        }
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Digest.encode_credentials(request.request_method, credentials, "#{password}", false)

        real_process_with_new_base_test(request, response)
      end
    )
  end
end

class ActionMailer::TestCase
  include ActionDispatch::Assertions::SelectorAssertions
end

class User
  def expired_auth_token
    auth_token (AUTH_TOKEN_EXPIRATION + 1.hour).ago
  end
end
