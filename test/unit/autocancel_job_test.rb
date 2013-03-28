require 'test_helper'

class AutocancelJobTest < ActiveSupport::TestCase
  test "autocancel" do
    recent_request = create :request
    old_request = create :request, created_at: 9.weeks.ago, open_at: 9.weeks.ago
    renewed_request = create :request, created_at: 9.weeks.ago, open_at: 4.weeks.ago
    granted_request = create :request, created_at: 9.weeks.ago, open_at: 9.weeks.ago
    granted_request.grant!

    job = AutocancelJob.new
    autocanceled_requests = job.perform

    autocanceled_requests.each do |request|
      assert request.canceled?, "request was not canceled: #{request}"
      assert Time.since(request.open_at) >= Request::AUTOCANCEL_THRESHOLD, "request was canceled before its time: #{request}"
      verify_event request, "autocancel"
    end

    assert_includes autocanceled_requests, old_request, "old request not autocanceled"
    assert !autocanceled_requests.include?(recent_request), "recent request was autocanceled"
    assert !autocanceled_requests.include?(renewed_request), "renewed request was autocanceled"
    assert !autocanceled_requests.include?(granted_request), "granted request was autocanceled"
  end
end
