# Manages flagging Donations and clearing those flags.
class FlagsController < ApplicationController
  def allowed_users
    case params[:action]
    when "new", "create" then [@donation.donor, @donation.fulfiller]
    when "fix", "destroy" then @donation.student
    end
  end

  def new
    @event = @donation.flag_events.build
  end

  def create
    @event = @donation.flag params[:event]
    if save @donation, @event
      flash[:notice] = "The request has been flagged, and your message has been sent to #{@donation.student.name}."
      redirect_to params[:redirect] || @donation.request
    else
      render :new
    end
  end

  def fix
    @event = @donation.fix_events.build
  end

  def destroy
    @event = @donation.fix params[:donation], params[:event]
    if save @donation, @event
      flash[:notice] = "Thank you. We've notified your donor (#{@donation.user.name})."
      redirect_to @donation.request
    else
      render :fix
    end
  end
end
