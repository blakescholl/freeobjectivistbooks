# Displays the logged-in-user homepage.
class ProfileController < ApplicationController
  before_filter :require_login

  def show
    @requests = @current_user.requests

    @pledge = @current_user.latest_pledge
    @pledge_donations_count = @pledge.donations.size if @pledge

    donations = @current_user.donations.active
    @show_donations = donations.any? || @current_user.pledges.any?

    @outstanding_donations = donations.needs_donor_action
    @flag_count = donations.unpaid.not_sent.flagged.count
    @any_eligible = @outstanding_donations.any? {|donation| donation.can_send_money?}

    @fulfillments = @current_user.fulfillments.needs_sending
    @show_fulfillments = @fulfillments.any? || @current_user.is_volunteer?
  end
end
