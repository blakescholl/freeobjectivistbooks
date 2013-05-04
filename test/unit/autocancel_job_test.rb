require 'test_helper'

class AutocancelJobTest < ActiveSupport::TestCase
  test "autocancel" do
    recent_request = create :request
    old_request = create :request, :open_too_long
    renewed_request = create :request, created_at: 9.weeks.ago, open_at: 4.weeks.ago
    granted_request = create :request, :open_too_long
    granted_request.grant!

    flagged_donation = create :donation, :flagged
    old_flagged_donation = Timecop.freeze(10.days.ago) {create :donation, :flagged}

    job = AutocancelJob.new
    autocanceled_requests = job.perform

    autocanceled_requests.each do |request|
      assert request.canceled?, "request was not canceled: #{request}"
      if request.open?
        assert Time.since(request.open_at) >= Request::AUTOCANCEL_OPEN_THRESHOLD, "open request canceled too soon: #{request}"
      elsif request.flagged?
        assert Time.since(request.flagged_at) >= Request::AUTOCANCEL_FLAG_THRESHOLD, "flagged request canceled too soon: #{request}"
      end
      verify_event request, "autocancel"
    end

    assert_includes autocanceled_requests, old_request, "old request not autocanceled"
    assert_includes autocanceled_requests, old_flagged_donation.request, "old flagged request not autocanceled"
    assert !autocanceled_requests.include?(recent_request), "recent request was autocanceled"
    assert !autocanceled_requests.include?(renewed_request), "renewed request was autocanceled"
    assert !autocanceled_requests.include?(granted_request), "granted request was autocanceled"
    assert !autocanceled_requests.include?(flagged_donation.request), "flagged request was autocanceled"
  end
end
