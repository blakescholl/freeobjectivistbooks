# Parent class for all admin controllers. Also manages the main admin dashboard at /admin.
class AdminController < ApplicationController
  before_filter :require_admin

  def index
    @user_count = User.count
    @request_count = Request.count
    @pledge_count = Pledge.count
    @event_count = Event.count
    @review_count = Review.count
    @referral_count = Referral.count
    @testimonial_count = Testimonial.count

    @latest_events = Event.reverse_order.limit(10)

    @metrics = Metrics.new
  end
end
