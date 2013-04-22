class PledgesController < ApplicationController
  def allowed_users
    @pledge.user
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
