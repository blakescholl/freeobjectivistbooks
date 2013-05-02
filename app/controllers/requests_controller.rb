# Manages Requests, including the list of open requests at /donate.
class RequestsController < ApplicationController
  before_filter :require_login
  before_filter :require_can_request, only: [:new, :create]
  before_filter :fix_if_needed, only: [:edit]
  before_filter :require_unsent_for_cancel, only: [:cancel, :destroy]
  before_filter :require_open_request, if: :is_renew?
  before_filter :require_renewable_request, only: [:edit], if: :is_renew?
  before_filter :require_can_request_for_reopen, if: :is_reopen?

  #--
  # Filters
  #++

  def parse_params
    @from_read = params[:from_read].to_bool
    @renew = params[:renew].to_bool || params[:action] == "renew"
  end

  def is_renew?
    @renew
  end

  def is_reopen?
    @renew && @request.canceled?
  end

  def allowed_users
    case params[:action]
    when "show" then [@request.user, @request.donor, @request.fulfiller]
    when "edit", "update", "cancel", "destroy", "renew" then @request.user
    end
  end

  def require_can_request
    unless @current_user.can_request?
      @request = @current_user.requests.not_granted.first
      render "no_new"
    end
  end

  def fix_if_needed
    if @request.flagged?
      redirect_to fix_flag_url(@request.flag)
    end
  end

  def require_unsent_for_cancel
    if !@request.canceled? && @request.sent?
      flash[:error] = "Can't cancel this request because the book has already been sent."
      redirect_to @request
    end
  end

  def require_open_request
    if !@request.open?
      flash[:error] = "This request has already been granted."
      redirect_to @request
    end
  end

  def require_renewable_request
    if !@request.can_renew?
      too_new = Time.since(@request.created_at) < Request::RENEW_THRESHOLD
      action = too_new ? "created" : "put back at the top of the list"
      flash[:error] = "Can't renew this request because it was #{action} recently."
      redirect_to @request
    end
  end

  def require_can_request_for_reopen
    if !@current_user.can_request?
      flash[:error] = "Can't reopen this request because you already have an open request."
      redirect_to @request
    end
  end

  #--
  # Actions
  #++

  def index
    @requests = Request.not_granted.includes(user: :location).includes(:book).reorder('open_at desc')

    all_donations = @current_user.donations.active
    @donations = all_donations.needs_donor_action.reorder(:created_at)
    @previous_count = all_donations.count - @donations.count
    @flag_count = all_donations.unpaid.not_sent.flagged.count
    @pledge = @current_user.current_pledge
  end

  def new
    @request = @current_user.new_request
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

  def show
    @actions = @request.actions_for @current_user, context: :detail
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

  def renew
    @event = @request.renew params[:request]
    if save @request, @event
      if @event
        flash[:notice] = case @event.detail
        when "renewed" then "Your request has been put back at the top of the list to find a donor."
        when "reopened" then "Your request has been reopened and back at the top of the list to find a donor."
        when "uncanceled" then "Your request has been reopened."
        end
      end
      redirect_to @request
    else
      render :edit
    end
  end
end
