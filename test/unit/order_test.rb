require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  def setup
    super
    @user = build :donor
    @donations = build_list :donation, 3, user: @user
  end

  # Total, balance, and contribution

  test "populate" do
    order = Order.new user: @user, donations: @donations
    assert_equal Money.parse(30), order.unpaid_total
    assert_equal Money.parse(0), order.balance
    assert_equal Money.parse(30), order.contribution
  end

  test "populate with balance" do
    @user.balance = 10
    order = Order.new user: @user, donations: @donations
    assert_equal Money.parse(30), order.unpaid_total
    assert_equal Money.parse(10), order.balance
    assert_equal Money.parse(20), order.contribution
  end

  test "populate with full balance" do
    @user.balance = 30
    order = Order.new user: @user, donations: @donations
    assert_equal Money.parse(30), order.unpaid_total
    assert_equal Money.parse(30), order.balance
    assert_equal Money.parse(0), order.contribution
  end

  test "populate with excess balance" do
    @user.balance = 50
    order = Order.new user: @user, donations: @donations
    assert_equal Money.parse(30), order.unpaid_total
    assert_equal Money.parse(30), order.balance
    assert_equal Money.parse(0), order.contribution
  end

  test "populate with negative balance" do
    @user.balance = -10 # should never happen, but just in case...
    order = Order.new user: @user, donations: @donations
    assert_equal Money.parse(30), order.unpaid_total
    assert_equal Money.parse(-10), order.balance
    assert_equal Money.parse(40), order.contribution
  end

  # Decription

  test "description" do
    order = Order.new user: @user, donations: @donations
    assert_match /Book \d+ to Student \d+ in Anytown, USA and 2 more books/, order.description
  end

  # Pay

  test "pay" do
    @user.balance = 30
    @user.save!
    @donations.each &:save!
    order = Order.create! user: @user, donations: @donations

    order.pay!

    assert order.paid?, "order is not paid"

    @user.reload
    assert_equal 0, @user.balance
  end
end
