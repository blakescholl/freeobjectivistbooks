# Manages Orders.
class OrdersController < ApplicationController
  def parse_params
    @abandoned = params[:abandoned].to_bool
  end

  def load_models
    super
    @donations = Donation.find_all_by_id params[:donation_ids] if params[:donation_ids]
  end

  def allowed_users
    if @order
      @order.user
    elsif @donations
      users = @donations.map {|d| d.user}.uniq
      raise ForbiddenException if users.size > 1  # should never happen
      users
    end
  end

  def create
    @order = Order.create! user: @current_user, donations: @donations
    redirect_to @order
  end

  def new_amazon_payment(order)
    AmazonPayment.new order.payment_options.merge(
        ipn_url: order_contributions_url(order),
        return_url: order_url(order),
        abandon_url: order_url(order, abandoned: true)
    )
  end

  def show
    if params['status'] && params['referenceId']
      @is_payment_return = true
      @payment_success = AmazonPayment.success_status?(params['status'])
      @contribution = Contribution.find_by_transaction_id params['transactionId'] if params['transactionId']
    end

    @amazon_payment = new_amazon_payment(@order) if !@payment_success && @order.needs_contribution?
  end
end
