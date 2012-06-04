class RequestsController < ApplicationController
  before_filter :require_login
  before_filter :require_can_request, only: [:new, :create]
  before_filter :require_unsent_for_cancel, only: [:cancel, :destroy]

  # Filters

  def parse_params
    @from_read = params[:from_read].to_bool
  end

  def allowed_users
    case params[:action]
    when "show" then [@request.user, @request.donor]
    when "edit", "update", "cancel", "destroy" then @request.user
    end
  end

  def require_can_request
    unless @current_user.can_request?
      @request = @current_user.requests.not_granted.first
      render "no_new"
    end
  end

  def require_unsent_for_cancel
    if !@request.canceled? && @request.sent?
      flash[:error] = "Can't cancel this request because the book has already been sent."
      redirect_to @request
    end
  end

  # Actions

  def index
    @requests = Request.not_granted.reorder('updated_at desc')
    @donations = @current_user.donations.active if @current_user
    @pledge = @current_user.pledges.first if @current_user
  end

  def new
    @request = @current_user.requests.build
  end

  def create
    @request = @current_user.requests.build
    @request.attributes = params[:request]
    if save @request
      redirect_to @request
    else
      render :new
    end
  end

  def edit
    if @request.flagged?
      redirect_to fix_donation_flag_url(@request.donation)
    else
      @event = @request.events.build type: "update"
    end
  end

  def update
    @request.attributes = params[:request]
    @event = @request.build_update_event
    if save @request, @event
      flash[:notice] = "Your info has been updated."
      redirect_to @request
    else
      render :edit
    end
  end

  def cancel
    if @request.canceled?
      flash[:notice] = "This request has already been canceled."
      redirect_to @request
    end

    @event = @request.cancel_request_events.build user: @current_user
  end

  def destroy
    @event = @request.cancel params[:request]
    if save @request, @request.donation, @event
      flash[:notice] = "Your request has been canceled."
      redirect_to profile_url
    else
      render :cancel
    end
  end
end
