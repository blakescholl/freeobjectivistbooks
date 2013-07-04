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

  def verify_payment_footer(which)
    assert_select '#payment' do
      assert_select 'form', (which.in? [:paypal, :balance])
      assert_select 'form[action*="paypal.com"]', (which == :paypal)
      assert_select '.summary', text: /existing balance/, count: (which == :balance ? 1 : 0)
      assert_select 'form[action^="/orders"]', (which == :balance)
      assert_select '.summary', text: /books have been paid for/, count: (which == :paid ? 1 : 0)
    end
  end

  test "show" do
    user = create :donor
    donations = create_list :donation, 2, user: user
    order = user.orders.create donations: donations

    get :show, {id: order.id}, session_for(user)
    assert_response :success

    assert_select 'h1', "Your donations"

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

    verify_payment_footer :paypal
  end

  test "show with partial balance" do
    user = create :donor, balance: 2
    donation = create :donation, user: user
    order = user.orders.create donations: [donation]

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

    verify_payment_footer :paypal
  end

  test "show with full balance" do
    user = create :donor, balance: 10
    donation = create :donation, user: user
    order = user.orders.create donations: [donation]

    get :show, {id: order.id}, session_for(user)
    assert_response :success

    assert_select '#total' do
      assert_select 'span', /total/i
      assert_select '.money', "$10"
    end

    assert_select '#balance', false
    assert_select '#contribution', false

    verify_payment_footer :balance
  end

  test "show paid" do
    user = create :donor
    donations = create_list :donation, 2, :paid, user: user
    order = user.orders.create donations: donations

    get :show, {id: order.id}, session_for(user)
    assert_response :success

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

    verify_payment_footer :paid
  end

  test "show requires login" do
    donation = create :donation
    order = donation.user.orders.create donations: [donation]

    get :show, {id: order.id}
    verify_login_page
  end

  test "show requires order owner" do
    donation = create :donation
    order = donation.user.orders.create donations: [donation]

    get :show, {id: order.id}, session_for(donation.student)
    verify_wrong_login_page
  end

  # Payment return

  def paypal_params(user, amount, status = 'Completed')
    {
        'payment_status' => status,
        'txn_id' => "5DW252222B671151W",
        'custom' => user.id.to_s,
        'payment_gross' => amount.to_money.to_s,
    }
  end

  test "show payment return" do
    user = create :donor
    donations = create_list :donation, 1, user: user
    order = user.orders.create donations: donations
    paypal_params = paypal_params(user, 10)
    order.contributions << Contribution.find_or_initialize_from_paypal_ipn(paypal_params)

    get :show, paypal_params.merge(id: order.id), session_for(user)
    assert_response :success

    assert_select '.notice' do
      assert_select '.headline', /thank/i
      assert_select '.detail', /received your contribution of \$10/
    end
    assert_select '.error', false

    verify_payment_footer :paid
  end

  test "show payment return before payment has been received" do
    user = create :donor
    donations = create_list :donation, 1, user: user
    order = user.orders.create donations: donations
    paypal_params = paypal_params(user, 10)

    get :show, paypal_params.merge(id: order.id), session_for(user)
    assert_response :success

    assert_select '.notice' do
      assert_select '.headline', /thank/i
      assert_select '.detail', /in a moment/
    end
    assert_select '.error', false

    verify_payment_footer :none
  end

  test "show payment pending" do
    user = create :donor
    donations = create_list :donation, 1, user: user
    order = user.orders.create donations: donations
    paypal_params = paypal_params(user, 10, 'Pending')

    get :show, paypal_params.merge(id: order.id), session_for(user)
    assert_response :success

    assert_select '.notice' do
      assert_select '.headline', /thank/i
      assert_select '.detail', /tomorrow/
    end
    assert_select '.error', false

    verify_payment_footer :none
  end

  test "show payment abandon" do
    user = create :donor
    donations = create_list :donation, 1, user: user
    order = user.orders.create donations: donations

    get :show, {id: order.id, abandoned: true}, session_for(user)
    assert_response :success

    assert_select '.error' do
      assert_select '.headline', /canceled/i
    end
    assert_select '.false', false

    verify_payment_footer :paypal
  end

  test "show payment error" do
    user = create :donor
    donations = create_list :donation, 1, user: user
    order = user.orders.create donations: donations
    paypal_params = paypal_params(user, 10, 'Failed')

    get :show, paypal_params.merge(id: order.id), session_for(user)
    assert_response :success

    assert_select '.error' do
      assert_select '.headline', /problem/i
    end
    assert_select '.false', false

    verify_payment_footer :paypal
  end

  # Pay

  test "pay" do
    user = create :donor, balance: 10
    donation = create :donation, user: user
    order = user.orders.create donations: [donation]

    put :pay, {id: order.id}, session_for(user)
    assert_redirected_to order

    order.reload
    assert order.paid?
  end

  test "pay requires login" do
    donation = create :donation
    order = donation.user.orders.create donations: [donation]

    put :pay, {id: order.id}
    verify_login_page
  end

  test "pay requires order owner" do
    donation = create :donation
    order = donation.user.orders.create donations: [donation]

    put :pay, {id: order.id}, session_for(donation.student)
    verify_wrong_login_page
  end
end
