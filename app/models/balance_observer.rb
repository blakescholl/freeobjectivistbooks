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
    end
  end

  def after_update(object)
    case object.class.name
    when "Donation"
      donation = object
      donation.unpay if donation.canceled?
    end
  end

  def after_destroy(object)
    case object.class.name
    when "Contribution"
      object.subtract_from_user_balance
    when "Donation" # should never happen
      object.unpay
    end
  end
end
