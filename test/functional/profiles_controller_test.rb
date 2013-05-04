require 'test_helper'

class ProfilesControllerTest < ActionController::TestCase
  # Show

  def verify_new_request_link(present = true)
    verify_link 'request another', present
  end

  def verify_donor_links(present = true)
    verify_link 'pledge', present
    verify_link 'see all your donations', present
  end

  def verify_volunteer_links(present = true)
    verify_link 'help out', present
    verify_link 'see all books you volunteered to send', present
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

    assert_select 'p', 'Studying architecture at Stanton Institute of Technology in New York, NY'
    assert_select 'a', /Edit your profile/

    assert_select '.request', /Atlas Shrugged/ do
      assert_select '.headline', /Atlas Shrugged/
      assert_select '.status', /We are looking for a donor/
      assert_select 'a', text: /thank/i, count: 0
      assert_select 'a', /see full/i
    end

    verify_can_request false
    verify_donor_links false
    verify_volunteer_links false

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
    verify_donor_links false
    verify_volunteer_links false

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
    verify_donor_links false
    verify_volunteer_links false

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
    verify_donor_links false
    verify_volunteer_links false

    assert_select 'h2', text: /donation/i, count: 0
  end

  test "show for requester with fulfiller" do
    @frisco_donation.fulfill @kira
    @frisco_donation.send! @kira

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
    user = create :donor, :with_pledge
    donation = create :donation, user: user
    ineligible_donation = create :donation_for_request_not_amazon, user: user
    create :donation_for_request_no_address, user: user
    create :donation, :sent, user: user
    create :donation, :paid, user: user

    get :show, params, session_for(user)
    assert_response :success

    assert_select 'p', 'In Anytown, USA'
    assert_select 'a', /Edit your profile/

    assert_select '.pledge' do
      assert_select 'p', /donate 5 books/
      assert_select 'a', /change/i
    end

    assert_select '.donation', 2 do
      assert_select '.headline a'
      assert_select '.shipping'
    end

    assert_select '.donation', /#{donation.book} to #{donation.student}/ do
      assert_select '.button.donation-send'
      assert_select '.button.donation-pay'
      assert_select '.book_price', "$10"

      assert_select '.shipping' do
        assert_select '.request .name', donation.student.name
        assert_select '.request .address', /\d+ Main St/
        assert_select '.actions form'
        assert_select '.actions a', 3
      end
    end

    assert_select '.donation', /#{ineligible_donation.book} to #{ineligible_donation.student}/ do
      assert_select '.button.donation-send'
      assert_select '.button.donation-pay', false

      assert_select '.shipping' do
        assert_select '.request .name', ineligible_donation.student.name
        assert_select '.request .address', /\d+ Main St/
        assert_select '.actions form'
        assert_select '.actions a', 2
      end
    end

    assert_select '#payment-button-row'

    verify_donor_links
    verify_new_request_link false
    verify_one_request_text false
    verify_volunteer_links false
  end

  test "show for donor with balance" do
    donor = create :donor, :with_pledge, balance: 20

    get :show, params, session_for(donor)
    assert_response :success

    assert_select 'p', /\$20 to spend/
  end

  test "show for donor with canceled pledge" do
    user = create :donor, :with_pledge
    user.cancel_pledge!

    get :show, params, session_for(user)
    assert_response :success

    assert_select '.pledge' do
      assert_select 'p', /None right now/
      assert_select 'a', /new/i
    end

    verify_donor_links
    verify_new_request_link false
    verify_one_request_text false
    verify_volunteer_links false
  end

  test "show for volunteer" do
    user = create :volunteer

    get :show, params, session_for(user)
    assert_response :success
    assert_select 'h1', /Volunteer \d+/

    assert_select 'h2', /volunteered/
    assert_select '.fulfillment', false

    verify_new_request_link false
    verify_one_request_text false
    verify_donor_links false
    verify_volunteer_links
  end

  test "show for volunteer with unsent fulfillments" do
    user = create :volunteer
    fulfillments = create_list :fulfillment, 3, user: user
    fulfillments.first.donation.send! user

    get :show, params, session_for(user)
    assert_response :success
    assert_select 'h1', /Volunteer \d+/

    assert_select 'h2', /volunteered/
    assert_select '.fulfillment', 2 do
      assert_select '.donation', /Book \d+ to Student \d+/
      assert_select '.donation', /On behalf of Donor \d+/
      assert_select '.actions a'
    end

    verify_new_request_link false
    verify_one_request_text false
    verify_donor_links false
    verify_volunteer_links
  end

  test "show requires login" do
    get :show
    verify_login_page
  end

  test "show to blocked user" do
    user = create :user, blocked: true

    get :show, params, session_for(user)
    assert_response :forbidden
    assert_select 'h1', 'Something is wrong with your account.'
  end

  # Edit

  test "edit for student" do
    user = create :student

    get :edit, params, session_for(user)
    assert_response :success

    assert_select 'h1', /profile/
    assert_select 'form' do
      assert_select 'input#user_name[value=?]', user.name
      assert_select 'input#user_name[placeholder]', false
      assert_select 'input#user_school[value=?]', user.school
      assert_select 'input#user_studying[value=?]', user.studying
      assert_select 'input#user_location_name[value=?]', user.location
      assert_select 'input[type=submit]'
    end

    assert_select 'a', /Cancel/
  end

  test "edit for donor" do
    user = create :donor, :with_pledge

    get :edit, params, session_for(user)
    assert_response :success

    assert_select 'h1', /profile/
    assert_select 'form' do
      assert_select 'input#user_name[value=?][placeholder]', user.name
      assert_select 'input#user_location_name[value=?]', user.location
      assert_select 'input#user_school', false
      assert_select 'input#user_studying', false
      assert_select 'input[type=submit]'
    end

    assert_select 'a', /Cancel/
  end

  test "edit for volunteer" do
    user = create :donor

    get :edit, params, session_for(user)
    assert_response :success

    assert_select 'h1', /profile/
    assert_select 'form' do
      assert_select 'input#user_name[value=?]', user.name
      assert_select 'input#user_name[placeholder]', false
      assert_select 'input#user_location_name[value=?]', user.location
      assert_select 'input#user_school', false
      assert_select 'input#user_studying', false
      assert_select 'input[type=submit]'
    end

    assert_select 'a', /Cancel/
  end

  test "edit requires login" do
    get :edit
    verify_login_page
  end

  # Update

  test "update" do
    user = create :user

    params = {name: "New Name", location_name: "New York, NY"}
    put :update, {user: params}, session_for(user)
    assert_redirected_to profile_path

    user.reload
    assert_equal "New Name", user.name
    assert_equal "New York, NY", user.location.name
  end

  test "update requires valid name" do
    user = create :user
    name = user.name

    params = {name: "User", location_name: user.location_name}
    put :update, {user: params}, session_for(user)
    assert_response :success

    assert_select 'div.field_with_errors' do
      assert_select 'input#user_name'
    end

    user.reload
    assert_equal name, user.name
  end

  test "update is safe against mass-assignment attacks" do
    user = create :user

    params = {roles: ["admin"], balance_cents: 100000}
    put :update, {user: params}, session_for(user)
    assert_redirected_to profile_path

    user.reload
    assert !user.is_admin?, "user made themselves admin"
    assert_equal 0, user.balance_cents
  end

  test "update requires login" do
    put :update
    verify_login_page
  end
end
