# Manages creating new Contributions; i.e., paying for donations.
class ContributionsController < ApplicationController
  before_filter :require_login, except: :create
  before_filter :verify_signature, only: :create

  def handle_unverified_request
    # PayPal wants to POST data to us on the return URL, so we allow POST for the test action.
    # Of course, PayPal doesn't have our CSRF token, so CSRF fails. Rails normally clears the
    # session when this happens. We're preventing that here. This is justified because we don't
    # actually create/modify any data in the test action; it might as well be a GET.
    # -Jason 4 Jul 2013
    super unless params[:action] == "test"
  end

  def load_models
    super
    @order = Order.find params[:order_id] if params[:order_id]
  end

  def verify_signature
    @signature = PaypalSignature.new request.request_parameters, request.raw_post
    if !Rails.env.test? && !@signature.valid?
      logger.error "Signature failed using params: #{request.request_parameters}, post: #{request.raw_post}"
      raise "PayPal response signature verification failed"
    end
  end

  def test
    @amount = Money.parse(params[:amount] || 10)
    @payment = PaypalPayment.new(
        amount: @amount,
        invoice: SecureRandom.uuid,
        item_name: "#{@amount.format} test",
        custom: @current_user.id,
        email: @current_user.email,
        is_live: false,
        notify_url: contributions_url,
        return: test_contributions_url,
        cancel_return: test_contributions_url(abandoned: true),
    )

    if params[:abandoned].to_bool
      flash.now[:error] = "Test payment abandoned"
    elsif PaypalPayment.success_status?(params['payment_status'])
      flash.now[:notice] = "Payment received: #{params['payment_gross']}"
    end
  end

  def create_contribution
    contribution = Contribution.find_or_initialize_from_paypal_ipn params
    return if !contribution

    logger.info "contribution: #{contribution.inspect}"
    return if @signature.sandbox?

    if @order
      @order.contributions << contribution
    else
      contribution.save!
    end
  end

  def create
    create_contribution
    render nothing: true
  end
end
