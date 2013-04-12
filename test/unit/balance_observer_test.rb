require 'test_helper'

class BalanceObserverTest < ActiveSupport::TestCase
  def setup
    super
    @user = create :donor, balance: 10
  end

  def build_contribution
    @contribution = @user.contributions.build amount_cents: 5000
  end

  def create_contribution
    build_contribution
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
  end

  test "balance unchanged when unpaid donation is canceled" do
    donation = create :donation, user: @user
    assert_difference "@user.balance", Money.parse(0) do
      donation.cancel! @user
      @user.reload
    end
  end
end
