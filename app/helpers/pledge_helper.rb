module PledgeHelper
  def feedback_for(pledge)
    what = pledge.recurring? ? "your pledge this month" : "this pledge"
    scope = pledge.recurring? ? "this month" : "towards this pledge"

    if !pledge.any_donations?
      if pledge.active?
        "You haven't donated any books #{scope} yet."
      else
        "You didn't get a chance to donate any books #{scope}, oh well."
      end
    else
      book_count = pluralize pledge.donations_count, "book"
      case pledge.status
      when :exceeded
        verb = "exceeded #{what} with #{book_count}"
        evaluations = ["amazing!", "excellent!", "fabulous!", "fantastic!", "magnificent!", "outstanding!", "terrific!", "wonderful!"]
      when :fulfilled
        verb = "fulfilled #{what}"
        evaluations = ["great!", "thank you!", "thanks a lot!"]
      else
        verb = "donated #{book_count} #{scope}"
        if pledge.active?
          verb += " so far"
          evaluations = ["thanks!", "thank you!"]
        else
          evaluations = ["not bad.", "not too shabby."]
        end
      end

      verb = "have #{verb}" if pledge.active?
      evaluation = evaluations.sample

      "You #{verb}, #{evaluation}"
    end
  end

  def pledge_summary(pledge)
    summary = "pledged to donate " + pluralize(pledge.quantity, "book")
    summary += " per month" if pledge.recurring?
    summary
  end
end
