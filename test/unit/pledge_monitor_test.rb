require 'test_helper'

class PledgeMonitorTest < ActiveSupport::TestCase
  test "end pledges if needed" do
    new_pledge = create :pledge
    old_pledge = create :pledge, :endable
    ended_pledge = create :pledge, :endable, :ended
    canceled_pledge = create :pledge, :endable, :canceled

    monitor = PledgeMonitor.new
    ended_pledges = monitor.perform

    ended_pledges.each do |pledge|
      assert pledge.ended?, "pledge was not ended: #{pledge}"
      assert !pledge.canceled?, "canceled pledge was ended: #{pledge}"
      assert pledge.created_at < Pledge::PLEDGE_PERIOD.ago, "pledge was ended too soon: #{pledge}"
    end

    assert_includes ended_pledges, old_pledge, "old pledge was not ended"
    assert !ended_pledges.include?(new_pledge), "new pledge was ended"
    assert !ended_pledges.include?(ended_pledge), "ended pledge was re-ended"
    assert !ended_pledges.include?(canceled_pledge), "canceled pledge was ended"
  end
end
