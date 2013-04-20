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
end
