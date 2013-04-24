class PledgesController < ApplicationController
  before_filter :require_login

  def allowed_users
    @pledge.user if @pledge
  end

  def new
    @pledge = @current_user.pledges.build quantity: 5
  end

  def create
    @pledge = @current_user.pledges.build params[:pledge]
    if save @pledge
      redirect_to donate_url
    else
      render :new
    end
  end

  def update
    @pledge.attributes = params[:pledge]
    @event = @pledge.build_update_event
    if save @pledge, @event
      redirect_to profile_url
    else
      render :edit
    end
  end

  def cancel
    @event = @pledge.cancel_pledge_events.build
  end

  def destroy
    @event = @pledge.cancel params[:pledge]
    if save @pledge, @event
      flash[:notice] = "Your pledge has been canceled."
      redirect_to profile_url
    else
      render :cancel
    end
  end
end
