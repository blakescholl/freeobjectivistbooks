require 'test_helper'

class ContributionTest < ActiveSupport::TestCase
  def setup
    super
    @contribution = @cameron.contributions.build amount_cents: 10000
  end

  # Validations

  test "valid contribution" do
    assert @contribution.valid?
  end

  test "validates amount" do
    @contribution.amount_cents = nil
    assert @contribution.invalid?
  end

  # Balance updates

  test "adding contribution updates user's balance" do
    assert_difference "@cameron.balance", @contribution.amount do
      @contribution.save!
      @cameron.reload
    end
  end

  test "deleting contribution updates user's balance" do
    @contribution.save!
    @cameron.reload

    assert_difference "@cameron.balance", -@contribution.amount do
      @contribution.destroy
      @cameron.reload
    end
  end
end
