require 'test_helper'

class OrdersControllerTest < ActionController::TestCase
  # Create

  def params(*donations)
    ids = Array(donations).flatten.map {|d| d.id}
    {donation_ids: ids}
  end

  def verify_order(order, *donations)
    Array(donations).flatten.each do |donation|
      donation.reload
      assert_equal order, donation.order
    end
  end

  test "create" do
    user = create :donor
    donations = create_list :donation, 2, user: user

    post :create, params(donations), session_for(user)

    donations.first.reload
    order = donations.first.order
    assert_redirected_to order

    verify_order order, donations
    assert_equal user, order.user
  end

  test "create requires donations" do
    user = create :donor

    post :create, params([]), session_for(user)
    assert_response 500
  end

  test "create requires eligible donations" do
    user = create :donor
    eligible = create :donation, user: user
    ineligible = create :donation_for_request_not_amazon, user: user

    post :create, params(eligible, ineligible), session_for(user)
    assert_response 500

    verify_order nil, eligible, ineligible
  end

  test "create requires login" do
    donation = create :donation

    post :create, params(donation)
    verify_login_page

    verify_order nil, donation
  end

  test "create requires donation owner" do
    user = create :donor
    donation = create :donation, user: user
    other_user = create :donor

    post :create, params(donation), session_for(other_user)
    verify_wrong_login_page

    verify_order nil, donation
  end

  test "create fails on mixed-user donation list" do
    donations = create_list :donation, 2

    post :create, params(donations), session_for(donations.first.user)
    verify_wrong_login_page

    verify_order nil, donations
  end

  # Show

  test "show" do
    user = create :donor
    donations = create_list :donation, 2, user: user
    order = Order.create user: user, donations: donations

    get :show, {id: order.id}, session_for(user)
    assert_response :success

    assert_select 'h1', "Make a payment"

    assert_select '.donation', 2 do
      assert_select 'a', /Book \d+ to Student \d+ in Anytown, USA/
      assert_select '.money', "$10"
    end

    assert_select '#total' do
      assert_select 'span', /total/i
      assert_select '.money', "$20"
    end

    assert_select '#balance', false
    assert_select '#contribution', false

    assert_select 'form[action*="amazon.com"]'
    assert_select 'form[action^="/orders"]', false
  end

  test "show with partial balance" do
    user = create :donor, balance: 2
    donation = create :donation, user: user
    order = Order.create user: user, donations: [donation]

    get :show, {id: order.id}, session_for(user)
    assert_response :success

    assert_select '#total' do
      assert_select 'span', /total/i
      assert_select '.money', "$10"
    end

    assert_select '#balance' do
      assert_select 'span', /balance/i
      assert_select '.money', "$2"
    end

    assert_select '#contribution' do
      assert_select 'span', /new contribution/i
      assert_select '.money', "$8"
    end

    assert_select 'form[action*="amazon.com"]'
    assert_select 'form[action^="/orders"]', false
  end

  test "show with full balance" do
    user = create :donor, balance: 10
    donation = create :donation, user: user
    order = Order.create user: user, donations: [donation]

    get :show, {id: order.id}, session_for(user)
    assert_response :success

    assert_select '#total' do
      assert_select 'span', /total/i
      assert_select '.money', "$10"
    end

    assert_select '#balance', false
    assert_select '#contribution', false

    assert_select 'p', /existing balance/

    assert_select 'form[action^="/orders"]'
    assert_select 'form[action*="amazon.com"]', false
  end
end
