# Manages creating new Contributions; i.e., paying for donations.
class ContributionsController < ApplicationController
  include ActionView::Helpers::TextHelper

  before_filter :require_login, except: :create
  before_filter :verify_signature, only: :create

  def load_models
    super
    @order = Order.find params[:order_id] if params[:order_id]
  end

  def verify_signature
    signature_params = params.subhash_without('controller', 'action')
    @signature = AmazonSignature.new signature_params, request.url
    raise UnauthorizedException if !Rails.env.test? && !@signature.valid?
  end

  def new_payment(options = {})
    AmazonPayment.new options.merge(
      ipn_url: contributions_url,
      return_url: thankyou_contributions_url,
      abandon_url: cancel_contributions_url,
    )
  end

  def new
    @donations = @current_user.donations.needs_payment

    if @donations.any?
      @total = @donations.map {|donation| donation.price}.sum

      donation = @donations.first
      description = "#{donation.book} to #{donation.student} in #{donation.student.location}"
      rest = @donations.count - 1
      description += " and " + pluralize(rest, "more book") if rest > 0

      @amazon_payment = new_payment amount: @total, reference_id: @current_user.id, description: description

      if params[:abandoned].to_bool
        flash.now[:error] = {
          headline: "Your contribution has been canceled.",
          detail: "We won't be able to send these books until you make a contribution to cover them."
        }
      end
    end
  end

  def test
    @amount = Money.parse(params[:amount] || 10)
    @amazon_payment = new_payment amount: @amount, reference_id: @current_user.id, description: "test", is_live: false
  end

  def create_contribution
    return if @signature.sandbox?

    contribution = Contribution.find_or_initialize_from_amazon_ipn params
    return if !contribution

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

  def thankyou
    if !AmazonPayment.success_status?(params['status'])
      flash[:error] = {
        headline: "Something went wrong with your payment. Try again?",
        detail: "We won't be able to send these books until you make a contribution to cover them."
      }
      redirect_to action: :new
    end
  end
end
