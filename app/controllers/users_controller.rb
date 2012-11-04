# Manages user signup of both students and donors.
class UsersController < ApplicationController
  before_filter :seen_signup, only: [:read, :donate]

  def seen_signup
    session[:seen_signup] = true
  end

  def load_models
    @user = User.new params[:user]
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
      if @user.pledges.any?
        redirect_to donate_url
      elsif @user.requests.any?
        redirect_to @user.requests.first
      else
        redirect_to profile_path
      end
    else
      render params[:from_action], status: :unprocessable_entity
    end
  end
end
