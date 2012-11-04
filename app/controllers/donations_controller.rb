# Manages actions on Donations.
class DonationsController < ApplicationController
  before_filter :require_login
  before_filter :require_can_cancel, only: [:cancel, :destroy]

  def event_detail
    params[:donation][:event][:detail] if params[:donation] && params[:donation][:event]
  end

  def reason
    @reason ||= params[:reason] || event_detail
  end

  # Filters

  def allowed_users
    case params[:action]
    when "cancel", "destroy"
      if reason == "not_received"
        @donation.student
      else
        @donation.user
      end
    end
  end

  def require_can_cancel
    unless @donation.can_cancel? @current_user
      flash[:error] = if @donation.sent?
        "This donation cannot be canceled because the book has already been sent."
      else
        "You have clicked an old link, or you have hit a bug. Email us if you need help."
      end
      redirect_to @donation.request
    end
  end

  # Actions

  def index
    @donations = @current_user.donations.active
  end

  def create
    @event = @request.grant @current_user
    if save @request, @event
      respond_to do |format|
        format.html { redirect_to @request }
        format.json { render json: @request, include: [:user, :book] }
      end
    else
      message = @request.donation.errors.full_messages.join ", "
      respond_to do |format|
        format.html do
          flash[:error] = message
          redirect_to @request
        end
        format.json do
          response = {message: message}
          render json: response, status: :bad_request
        end
      end
    end
  end

  def cancel
    @event = @donation.cancel_request_events.build user: @current_user, detail: reason
    render reason || :cancel
  end

  def destroy
    @event = @donation.cancel params[:donation], @current_user
    if save @donation, @event
      if @current_user == @donation.donor
        if @event
          flash[:notice] = {
            headline: "We let #{@donation.student.name} know that you canceled this donation.",
            detail: "We will try to find another donor for them."
          }
        end
        redirect_to donations_url
      else
        flash[:notice] = "We've put you back at the top of the list and will keep looking for a donor for you."
        redirect_to @donation.request
      end
    else
      render reason || :cancel
    end
  end
end
