require 'test_helper'

class OrdersControllerTest < ActionController::TestCase
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
end
