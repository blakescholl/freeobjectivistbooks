# Manages forgotten passwords and password resets.
class PasswordsController < ApplicationController
  before_filter :require_ssl
  before_filter :validate_auth, only: [:edit, :update]
  rescue_from(User::AuthTokenExpired) { render :expired_reset }
  rescue_from(User::AuthTokenInvalid) { render :invalid_reset }

  def parse_params
    @email = params[:email]
  end

  def request_reset
    @user = User.find_by_email @email unless @email.blank?
    if @user
      UserMailer.reset_password(@user).deliver
    else
      @error = @email.blank? ? "Please enter an email address" : "No user with that email"
      render :forgot
    end
  end

  def validate_auth
    set_current_user nil
    @user = User.find_by_auth_token params[:auth]
  end

  def update
    if @user.update_attributes params[:user]
      set_current_user @user
      flash[:notice] = "Your password has been reset."
      redirect_to root_url
    else
      log_errors @user
      render :edit
    end
  end
end
