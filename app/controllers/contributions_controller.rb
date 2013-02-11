# Manages creating new Contributions; i.e., paying for donations.
class ContributionsController < ApplicationController
  include ActionView::Helpers::TextHelper

  before_filter :require_login, except: :create

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
    @ref = SecureRandom.hex 3
    @amazon_payment = new_payment amount: @amount, reference_id: @ref, description: "test #{@ref}", is_live: false
  end

  def create
    logger.info "params: #{params.inspect}"
    render nothing: true
  end
end
