require 'test_helper'

class BalanceObserverTest < ActiveSupport::TestCase
  def setup
    super
    @user = create :donor, balance: 10
  end

  def build_contribution(amount = nil)
    amount ||= 50
    @contribution = @user.contributions.build amount_cents: amount.to_money.cents
  end

  def create_contribution(amount = nil)
    build_contribution amount
    @contribution.save!
    @user.reload
  end

  test "balance increased when contribution created" do
    build_contribution
    assert_difference "@user.balance", @contribution.amount do
      @contribution.save!
      @user.reload
    end
  end

  test "associated order paid for when contribution created" do
    donations = create_list :donation, 2, user: @user
    order = Order.create user: @user, donations: donations
    contribution = build_contribution 10
    order.contributions << contribution
    order.reload
    assert order.paid?, "order is not paid"
  end

  test "balance decreased when contribution deleted" do
    create_contribution
    assert_difference "@user.balance", -@contribution.amount do
      @contribution.destroy
      @user.reload
    end
  end

  test "balance increased when paid-for donation is canceled" do
    donation = create :donation, :paid, user: @user
    assert_difference "@user.balance", donation.price do
      donation.request.cancel!
      @user.reload
    end

    donation.reload
    assert !donation.paid?, "donation still paid"
    assert donation.refunded?, "donation not refunded"
  end

  test "balance unchanged when unpaid donation is canceled" do
    donation = create :donation, user: @user
    assert_difference "@user.balance", Money.parse(0) do
      donation.cancel! @user
      @user.reload
    end
  end
end
