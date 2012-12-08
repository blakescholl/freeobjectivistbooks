# Manages changes to Donation status, like "sent" or "received".
class StatusesController < ApplicationController
  before_filter :require_login
  before_filter :require_status

  def donation_status
    params[:donation][:status] if params[:donation]
  end

  def status
    @status ||= params[:status] || donation_status
  end

  #--
  # Filters
  #++

  def allowed_users
    case status
    when "sent" then [@donation.user, @donation.fulfiller]
    when "received", "read" then @donation.student
    end
  end

  def require_status
    render_not_found if status.blank?
  end

  #--
  # Actions
  #++

  def edit
    if status == "sent"
      redirect_to @donation.request
    else
      @event = @donation.update_status_events.build detail: status, user: @current_user
      @review = @donation.build_review
      render status
    end
  end

  def notice
    case status
    when "sent" then "Thanks! We've let #{@event.recipients.to_sentence} know the book is on its way."
    when "received" then "Great! We've let #{@event.recipients.to_sentence} know that you received this book."
    when "read" then "Great! #{@event.recipients.to_sentence} will be glad to hear that you finished this book."
    end
  end

  def redirect_destination
    return params[:redirect] if params[:redirect]

    case status
    when "sent", "received" then @donation.request
    when "read"
      @current_user.can_request? ? new_request_url(from_read: true) : profile_url
    end
  end

  def update
    @event = @donation.update_status params[:donation], @current_user
    @review = @donation.build_review params[:review] if params[:review] && params[:review][:text].present?

    if save @donation, @review, @event
      respond_to do |format|
        format.html do
          flash[:notice] = notice
          redirect_to redirect_destination
        end
        format.js { render nothing: true }
      end
    else
      render status
    end
  end
end
