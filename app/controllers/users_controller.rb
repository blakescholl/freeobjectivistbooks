# Manages user signup of both students and donors.
class UsersController < ApplicationController
  before_filter :require_ssl
  before_filter :seen_signup, only: [:read, :donate, :volunteer]

  def seen_signup
    session[:seen_signup] = true
  end

  def load_models
    @user = User.new params[:user]
    @user.donor_mode = params[:donor_mode] if params[:donor_mode].present?
    @request = @user.requests.build params[:request] if params[:request]
    @pledge = @user.pledges.build params[:pledge] if params[:pledge]
  end

  def read
    @request ||= @user.new_request
  end

  def donate
    @pledge ||= @user.pledges.build quantity: 5
  end

  def create
    referral_id = session[:referral_id]
    @user.referral_id = referral_id
    @request.referral_id = referral_id if @request
    @pledge.referral_id = referral_id if @pledge

    if save @user
      set_current_user @user
      redirect_to case params[:from_action]
      when "donate" then donate_url
      when "read" then @user.requests.first
      when "volunteer" then volunteer_thanks_url
      else profile_url
      end
    else
      render params[:from_action], status: :unprocessable_entity
    end
  end
end
