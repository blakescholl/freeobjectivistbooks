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

  def new_paypal_payment(order)
    PaypalPayment.new order.paypal_payment_options.merge(
        notify_url: order_contributions_url(order),
        return: order_url(order),
        cancel_return: order_url(order, abandoned: true)
    )
  end

  def show
    if (params['payment_status'] && params['txn_id']) || @abandoned
      @is_payment_return = true
      @payment_success = PaypalPayment.success_status?(params['payment_status'])
      @payment_pending = PaypalPayment.pending_status?(params['payment_status'])
      @contribution = Contribution.find_by_transaction_id params['txn_id'] if params['txn_id']
    end

    @payment = new_paypal_payment(@order) if !@payment_success && @order.needs_contribution?
  end

  def pay
    @order.pay!
    redirect_to @order
  end
end
