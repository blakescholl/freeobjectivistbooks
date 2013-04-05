# Manages sending messages between students and their donors.
class MessagesController < ApplicationController
  before_filter :verify_reply_to

  def load_models
    super
    reply_to_event_id = params[:reply_to_event_id]
    reply_to_event_id ||= params[:event][:reply_to_event_id] if params[:event]
    @reply_to_event = Event.find reply_to_event_id if reply_to_event_id.present?
  end

  def allowed_users
    params[:is_thanks] ? @donation.student : [@donation.student, @donation.donor, @donation.fulfiller]
  end

  def verify_reply_to
    raise "Reply-to event doesn't match!" if @reply_to_event && @reply_to_event.donation != @donation
  end

  def render_form
    render @event.is_thanks? ? "thank" : "new"
  end

  def new
    attributes = params.subhash :is_thanks, :reply_to_event_id
    @event = @donation.new_message @current_user, attributes
    render_form
  end

  def create
    attributes = params[:event].merge(user: @current_user)
    @event = @donation.message_events.build attributes
    if save @event
      message = @event.is_thanks? ? "thanks" : "message"
      flash[:notice] = "We sent your #{message} to #{@event.recipients.to_sentence}."
      redirect_to @donation.request
    else
      render_form
    end
  end
end
