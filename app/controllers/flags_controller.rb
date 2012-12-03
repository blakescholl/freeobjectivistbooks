# Manages flagging Donations and clearing those flags.
class FlagsController < ApplicationController
  include ApplicationHelper

  def allowed_users
    case params[:action]
    when "new", "create" then [@donation.donor, @donation.fulfiller]
    when "fix", "destroy" then @donation.student
    end
  end

  def new
    @event = @donation.flag_events.build user: @current_user
  end

  def create
    @event = @donation.flag params[:event].merge(user: @current_user)
    if save @donation, @event
      flash[:notice] = "The request has been flagged, and your message has been sent to #{@donation.student}."
      redirect_to params[:redirect] || @donation.request
    else
      render :new
    end
  end

  def fix
    @event = @donation.fix_events.build
  end

  def destroy
    @flag_event = @donation.flag_events.last
    @event = @donation.fix params[:donation], params[:event]
    if save @donation, @event
      user = @flag_event.user
      role = role_description @flag_event.user_role
      flash[:notice] = "Thank you. We've notified #{user} (#{role}), who will send your book."
      redirect_to @donation.request
    else
      render :fix
    end
  end
end
