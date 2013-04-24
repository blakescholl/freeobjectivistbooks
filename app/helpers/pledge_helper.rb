module PledgeHelper
  def feedback_for(pledge)
    if !pledge.any_donations?
      if pledge.active?
        "You haven't donated any books towards this pledge yet."
      else
        "You didn't get a chance to donate any books towards this pledge, oh well."
      end
    else
      book_count = pluralize pledge.donations_count, "book"
      case pledge.status
      when :exceeded
        verb = "exceeded this pledge with #{book_count}"
        evaluations = ["amazing!", "excellent!", "fabulous!", "fantastic!", "magnificent!", "outstanding!", "terrific!", "wonderful!"]
      when :fulfilled
        verb = "fulfilled this pledge"
        evaluations = ["great!", "thank you!", "thanks a lot!"]
      else
        verb = "donated #{book_count} towards this pledge"
        if pledge.active?
          verb += " so far"
          evaluations = ["thanks!", "thank you!"]
        else
          evaluations = ["not bad.", "not too shabby.", "better than nothing!"]
        end
      end

      verb = "have #{verb}" if pledge.active?
      evaluation = evaluations.sample

      "You #{verb}, #{evaluation}"
    end
  end
end
