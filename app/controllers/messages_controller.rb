# Manages sending messages between students and their donors.
class MessagesController < ApplicationController
  def allowed_users
    params[:is_thanks] ? @donation.student : [@donation.student, @donation.donor, @donation.fulfiller]
  end

  def render_form
    render @event.is_thanks? ? "thank" : "new"
  end

  def new
    @event = @donation.new_message @current_user, params[:is_thanks]
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
