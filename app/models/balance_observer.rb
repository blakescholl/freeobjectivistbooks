class BalanceObserver < ActiveRecord::Observer
  observe :contribution, :donation

  #--
  # NOTE: We switch on class names here rather than classes directly because of a problem with ActiveAdmin and class
  # caching. When classes are not cached in development mode, ActiveAdmin is still holding on to the original classes
  # and these case statements don't behave the way you'd expect. Hence switching on strings instead of the classes
  # themselves. For a bit of context, see: https://github.com/gregbell/active_admin/issues/835
  #++

  def after_create(object)
    case object.class.name
    when "Contribution"
      contribution = object
      contribution.add_to_user_balance
      donations = contribution.user.donations.needs_payment
      donations = donations.readonly(false).reorder(:created_at)
      donations.each do |donation|
        donation.pay_if_covered
      end
    when "Donation"
      object.pay_if_covered
    end
  end

  def after_update(object)
    case object.class.name
    when "Donation"
      donation = object
      donation.unpay if donation.canceled_changed? && donation.canceled?
    end
  end

  def after_destroy(object)
    user = object.user
    case object.class.name
    when "Contribution"
      object.subtract_from_user_balance
    when "Donation" # should never happen
      object.unpay
    end
  end
end
