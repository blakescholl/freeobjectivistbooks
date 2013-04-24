# Turns over pledges that are ready to end, thereby invoking the PledgeMailer.
class PledgeMonitor
  def end_pledges_if_needed(pledges)
    pledges = pledges.reject {|pledge| pledge.ended?}
    pledges.inject([]) do |ended,pledge|
      pledge.end_if_needed!
      if pledge.ended?
        Rails.logger.info "Ended pledge #{pledge.id} of #{pledge.quantity} books by #{pledge.user} " +
          "on #{pledge.created_at.to_date}, #{pledge.status} with #{pledge.donations_count} donations"
        ended << pledge
      end
      ended
    end
  end

  def perform
    pledges = Pledge.needs_ending.includes(:user)
    end_pledges_if_needed pledges
  end

  def self.schedule
    Delayed::Job.enqueue new
  end
end
