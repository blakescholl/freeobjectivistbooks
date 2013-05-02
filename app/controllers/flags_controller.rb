# Manages flagging Donations and clearing those flags.
class FlagsController < ApplicationController
  include ApplicationHelper

  def allowed_users
    case params[:action]
    when "new", "create" then @donation.sender
    when "fix", "destroy" then @flag.student
    end
  end

  def new
    @flag = @donation.flags.build user: @current_user, type: 'shiping_info'
  end

  def create
    flag_params = params[:flag].merge type: 'shipping_info'
    @event = @donation.add_flag flag_params, @current_user
    if save @donation, @event
      flash[:notice] = "The request has been flagged, and your message has been sent to #{@donation.student}."
      redirect_to params[:redirect] || @donation.request
    else
      @flag = @donation.flag
      render :new
    end
  end

  def destroy
    @event = @flag.fix params[:flag]
    if save @flag, @flag.donation, @event
      flash[:notice] = "Thank you. We've notified #{@flag.user} (#{role_description @flag.user_role}), who will send your book."
      redirect_to @flag.request
    else
      render :fix
    end
  end
end
