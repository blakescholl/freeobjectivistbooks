require 'test_helper'

class BalanceObserverTest < ActiveSupport::TestCase
  def build_contribution
    @contribution = @cameron.contributions.build amount_cents: 5000
  end

  def create_contribution
    build_contribution
    @contribution.save!
    @cameron.reload
  end

  test "balance increased when contribution created" do
    build_contribution
    assert_difference "@cameron.balance", @contribution.amount do
      @contribution.save!
      @cameron.reload
    end
  end

  test "balance decreased when contribution deleted" do
    create_contribution
    assert_difference "@cameron.balance", -@contribution.amount do
      @contribution.destroy
      @cameron.reload
    end
  end

  test "new donation paid for if balance covers it" do
    donation = nil
    assert_difference "@cameron.balance", -@atlas.price do
      donation = @howard_request.grant! @cameron
      @cameron.reload
    end

    assert donation.paid?
  end

  test "new donation not paid for if price exceeds balance" do
    @atlas.price = @cameron.balance + 25.to_money
    @atlas.save!

    donation = nil
    assert_difference "@cameron.balance", 0.to_money do
      donation = @howard_request.grant! @cameron
      @cameron.reload
    end

    assert !donation.paid?
  end

  test "new contribution pays for outstanding donations" do
    @atlas.price = @cameron.balance + 25.to_money
    @atlas.save!
    donation = @howard_request.grant! @cameron

    build_contribution
    assert_difference "@cameron.balance", (@contribution.amount - donation.price) do
      @contribution.save!
      @cameron.reload
    end

    donation.reload
    assert donation.paid?
  end
end
