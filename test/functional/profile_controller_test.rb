require 'test_helper'

class ProfileControllerTest < ActionController::TestCase
  def verify_new_request_link(present = true)
    verify_link 'request another', present
  end

  def verify_all_donations_link(present = true)
    verify_link 'see all your donations', present
  end

  def verify_volunteer_link(present = true)
    verify_link 'help out', present
  end

  def verify_one_request_text(present = true)
    assert_select 'p', text: /one open request/, count: (present ? 1 : 0)
  end

  def verify_can_request(can_request = true)
    verify_new_request_link can_request
    verify_one_request_text !can_request
  end

  test "show for requester with no donor" do
    get :show, params, session_for(@howard)
    assert_response :success
    assert_select 'h1', "Howard Roark"

    assert_select '.request', /Atlas Shrugged/ do
      assert_select '.headline', /Atlas Shrugged/
      assert_select '.status', /We are looking for a donor/
      assert_select 'a', text: /thank/i, count: 0
      assert_select 'a', /see full/i
    end

    verify_can_request false
    verify_all_donations_link false
    verify_volunteer_link false

    assert_select 'h2', text: /donation/i, count: 0
  end

  test "show for requester with donor" do
    get :show, params, session_for(@quentin)
    assert_response :success
    assert_select 'h1', "Quentin Daniels"

    assert_select '.request', /Virtue of Selfishness/ do
      assert_select '.headline', /The Virtue of Selfishness/
      assert_select '.status', /Hugh Akston has sent/
      assert_select 'a', /Let Hugh Akston know when you have received/i
      assert_select 'a', text: /thank/i, count: 0
      assert_select 'a', /see full/i
    end

    assert_select '.request', /Fountainhead/ do
      assert_select '.headline', /The Fountainhead/
      assert_select '.status', /Hugh Akston in Boston, MA will donate/
      assert_select 'a', /thank/i
      assert_select 'a', /see full/i
    end

    assert_select '.request', /Atlas Shrugged/ do
      assert_select '.headline', /Atlas Shrugged/
      assert_select '.status', /Quentin Daniels has read this book./
      assert_select '.flagged', false
      assert_select 'a', text: /Let .* know/, count: 0
      assert_select 'a', text: /thank/i, count: 0
      assert_select 'a', /see full/i
    end

    verify_can_request false
    verify_all_donations_link false
    verify_volunteer_link false

    assert_select 'h2', text: /donation/i, count: 0
  end

  test "show for requester with donor but no address" do
    get :show, params, session_for(@dagny)
    assert_response :success
    assert_select 'h1', "Dagny"

    assert_select '.request', /Capitalism/ do
      assert_select '.headline', /Capitalism/
      assert_select '.status', /Hugh Akston in Boston, MA will donate/
      assert_select '.flagged', /We need your address/
      assert_select 'a', /add your address/i
      assert_select 'a', text: /thank/i, count: 0
      assert_select 'a', /see full/i
    end

    verify_can_request
    verify_all_donations_link false
    verify_volunteer_link false

    assert_select 'h2', text: /donation/i, count: 0
  end

  test "show for requester with flagged address" do
    get :show, params, session_for(@hank)
    assert_response :success
    assert_select 'h1', "Hank Rearden"

    assert_select '.request', /Atlas Shrugged/ do
      assert_select '.headline', /Atlas Shrugged/
      assert_select '.status', /Henry Cameron in New York, NY will donate/
      assert_select '.flagged', /problem with your shipping info/
      assert_select 'a', /update/i
      assert_select 'a', text: /thank/i, count: 0
      assert_select 'a', /see full/i
    end

    assert_select '.request', /Fountainhead/ do
      assert_select '.headline', /The Fountainhead/
      assert_select '.status', /Hank Rearden has received/
      assert_select '.flagged', false
      assert_select 'a', /Let Henry Cameron know when you have finished reading/
      assert_select 'a', text: /thank/i, count: 0
      assert_select 'a', /see full/i
    end

    verify_can_request
    verify_all_donations_link false
    verify_volunteer_link false

    assert_select 'h2', text: /donation/i, count: 0
  end

  test "show for requester with fulfiller" do
    @frisco_donation.fulfill @kira
    @frisco_donation.update_status! "sent", @kira

    get :show, params, session_for(@frisco)
    assert_response :success
    assert_select 'h1', "Francisco d&#x27;Anconia"

    assert_select '.request', /Objectivism:/ do
      assert_select '.headline', /Objectivism:/
      assert_select '.status', /Kira Argounova has sent/
      assert_select '.flagged', false
      assert_select 'a', /Let Henry Cameron and Kira Argounova know when you have received/
      assert_select 'a', text: /thank/i, count: 0
      assert_select 'a', /see full/i
    end
  end

  test "show for donor" do
    get :show, params, session_for(@hugh)
    assert_response :success
    assert_select 'h1', "Hugh Akston"

    assert_select '.pledge .headline', /You pledged to donate 5 books/
    assert_select 'h2', 'Outstanding donations'

    assert_select '.donation', text: /The Virtue of Selfishness/, count: 0      # sent
    assert_select '.donation', text: /Capitalism: The Unknown Ideal/, count: 0  # flagged
    assert_select '.donation', text: /Atlas Shrugged/, count: 0                 # also flagged

    assert_select '.donation', /The Fountainhead to/ do
      assert_select '.request .name', /Quentin Daniels/
      assert_select '.request .address', /123 Main St/
      assert_select '.actions a', /see full/i
      assert_select '.actions a', /flag/i
      assert_select '.actions a', /cancel/i
      assert_select '.actions .flagged', false
    end

    verify_all_donations_link
    verify_new_request_link false
    verify_one_request_text false
    verify_volunteer_link false

    assert_select 'a', 'See all your donations'
  end

  test "show for volunteer" do
    get :show, params, session_for(@kira)
    assert_response :success
    assert_select 'h1', "Kira Argounova"

    verify_new_request_link false
    verify_one_request_text false
    verify_all_donations_link false
    verify_volunteer_link
  end

  test "show requires login" do
    get :show
    assert_response :unauthorized
    assert_select 'h1', 'Log in'
  end

  # Blocked user

  test "blocked user" do
    @stadler.update_attributes! blocked: true

    get :show, params, session_for(@stadler)
    assert_response :forbidden
    assert_select 'h1', 'Something is wrong with your account.'
  end
end
