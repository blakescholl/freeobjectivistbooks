class PledgesController < ApplicationController
  def allowed_users
    @pledge.user
  end

  def update
    @pledge.attributes = params[:pledge]
    if save @pledge
      redirect_to profile_url
    else
      render :edit
    end
  end
end
