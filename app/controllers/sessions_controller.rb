# Manages login and logout.
class SessionsController < ApplicationController
  skip_before_filter :reject_blocked_users
  before_filter :require_ssl

  def parse_params
    @destination = params[:destination]
  end

  def create
    user = User.login params[:email], params[:password]
    if user
      set_current_user user
      redirect_to @destination || root_url
    else
      @error = "Incorrect email or password."
      render :new
    end
  end

  def destroy
    set_current_user nil
    redirect_to root_url
  end
end
