# Manages fulfillment of Donations.
class FulfillmentsController < ApplicationController
  before_filter :require_volunteer

  def allowed_users
    @fulfillment.user if params[:action] == "show"
  end

  def volunteer
    donations = Donation.needs_fulfillment.reorder(:created_at)
    @unclaimed = donations.map {|donation| donation.build_fulfillment}
    @unsent = @current_user.fulfillments.needs_sending
  end

  def index
    fulfillments = @current_user.fulfillments
    @needs_sending = fulfillments.needs_sending
    @flagged = fulfillments.flagged
    @sent = fulfillments.sent
  end

  def create
    begin
      fulfillment = @donation.fulfill @current_user
      redirect_to fulfillment
    rescue Donation::AlreadyFulfilled
      flash[:error] = "Oops, that book is already being sent by #{@donation.fulfillment.user.name}. Please choose another!"
      redirect_to volunteer_url
    end
  end

  def show
  end
end
