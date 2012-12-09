class BalanceObserver < ActiveRecord::Observer
  observe :contribution, :donation

  def after_create(object)
    case object
    when Contribution
      contribution = object
      contribution.add_to_user_balance
      donations = contribution.user.donations.needs_payment.reorder(:created_at)
      donations.each do |donation|
        donation.pay_if_covered
      end
    when Donation
      object.pay_if_covered
    end
  end

  def after_update(object)
    case object
    when Donation
      donation = object
      donation.unpay if donation.canceled_changed? && donation.canceled?
    end
  end

  def after_destroy(object)
    user = object.user
    case object
    when Contribution
      object.subtract_from_user_balance
    when Donation # should never happen
      object.unpay
    end
  end
end
