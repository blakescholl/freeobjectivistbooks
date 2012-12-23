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
    @event = @donation.flag params[:event], @current_user
    if save @donation, @event
      flash[:notice] = "The request has been flagged, and your message has been sent to #{@donation.student}."
      redirect_to params[:redirect] || @donation.request
    else
      render :new
    end
  end

  def fix
    @flag_event = @donation.flag_event
    @event = @donation.fix_events.build
  end

  def destroy
    @flag_event = @donation.flag_event
    @event = @donation.fix params[:donation], params[:event]
    if save @donation, @event
      flash[:notice] = if @flag_event
        user = @flag_event.user
        role = @flag_event.user_role
        "Thank you. We've notified #{user} (#{role_description role}), who will send your book."
      else
        "Thank you."
      end
      redirect_to @donation.request
    else
      render :fix
    end
  end
end
