# Displays the logged-in-user homepage.
class ProfilesController < ApplicationController
  before_filter :require_login

  def load_models
    @user = @current_user
  end

  def show
    @requests = @user.requests

    @pledge = @user.latest_pledge
    @pledge_donations_count = @pledge.donations.size if @pledge

    donations = @user.donations.active
    @show_donations = donations.any? || @user.pledges.any?

    @outstanding_donations = donations.needs_donor_action
    @flag_count = donations.unpaid.not_sent.flagged.count
    @any_eligible = @outstanding_donations.any? {|donation| donation.can_send_money?}

    @fulfillments = @user.fulfillments.needs_sending
    @show_fulfillments = @fulfillments.any? || @user.is_volunteer?
  end

  def edit
    @type = if @user.requests.any?
      :student
    elsif @user.pledges.any? || @user.donations.any?
      :donor
    elsif @user.is_volunteer?
      :volunteer
    end
  end

  def update
    @user.attributes = params[:user]
    if save @user
      redirect_to action: :show
    else
      render :edit
    end
  end
end
