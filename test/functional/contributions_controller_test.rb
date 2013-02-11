# encoding: UTF-8

require 'test_helper'

class ContributionsControllerTest < ActionController::TestCase
  def setup
    @donor = create :send_money_donor
  end

  # New

  test "new" do
    donations = create_list :donation, 2, user: @donor

    get :new, params, session_for(@donor)
    assert_response :success

    assert_select 'h1', "Your donations"
    assert_select 'li', text: /Book \d+ to Student \d+ in Anytown, USA –\s+\$10/, count: 2
    assert_select 'p', /Total for your donations: \$20/
    assert_select 'form'
  end

  test "new with no donations" do
    get :new, params, session_for(@donor)
    assert_response :success

    assert_select 'h1', "Your donations"
    assert_select 'li', false
    assert_select 'form', false
    assert_select 'p', /No donations/
    assert_select 'a', /Find students/
  end

  test "new with no donations in send-books mode" do
    donor2 = create :send_books_donor

    get :new, params, session_for(donor2)
    assert_response :success

    assert_select 'h1', "Your donations"
    assert_select 'li', false
    assert_select 'form', false
    assert_select 'p', /Your account is set up to send books directly/
  end

  # Create

  test "create" do
    post :create
    assert_response :success
    # this is still a stub for now
  end

  # Thank-you

  test "thankyou" do
    get :thankyou, params, session_for(@donor)
    assert_response :success
    assert_select 'h1', "Thank you"
    assert_select 'p', /Thank you/
    assert_select 'a', /Find more/
  end

  # Cancel

  test "cancel" do
    donations = create_list :donation, 2, user: @donor

    get :new, {abandoned: true}, session_for(@donor)
    assert_response :success

    assert_select 'h1', "Your donations"
    assert_select 'li', 2
    assert_select 'form'
    assert_select '.error .headline', /canceled/
  end

  # Test

  test "test" do
    get :test, params, session_for(@donor)
    assert_response :success
    assert_select 'form'
  end
end
