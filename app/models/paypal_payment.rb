# Represents a payment to be made through PayPal.
class PaypalPayment
  extend ActiveModel::Naming

  # Documentation on PayPal form params:
  # https://developer.paypal.com/webapps/developer/docs/classic/paypal-payments-standard/integration-guide/Appx_websitestandard_htmlvariables/
  attr_reader :cmd, :business, :item_name, :amount, :currency_code, :invoice, :custom, :email, :no_shipping, :is_live
  attr_reader :notify_url, :return, :cancel_return

  def self.success_status?(status)
    # https://developer.paypal.com/webapps/developer/docs/classic/ipn/integration-guide/IPNandPDTVariables/
    status.in? %w{Completed Created Processed Pending}
  end

  def self.pending_status?(status)
    # https://developer.paypal.com/webapps/developer/docs/classic/ipn/integration-guide/IPNandPDTVariables/
    status == "Pending"
  end

  def initialize(attributes = {})
    @cmd = "_xclick"
    @business = "donations@freeobjectivistbooks.org"
    @currency_code = "USD"
    @no_shipping = "1" # don't prompt for shipping
    @is_live = true

    attributes.each do |attr,value|
      instance_variable_set "@#{attr}", value
    end
  end

  # Action URL to use in an HTML form to submit this payment, using POST.
  def form_submit_url
    "https://#{form_submit_host}#{form_submit_path}"
  end

  # Parameters that should be included in the HTML form as hidden inputs.
  def params
    hash_from_methods keys
  end

private

  def form_submit_host
    env = ".sandbox" if !is_live || !Rails.application.config.payments_live
    "www#{env}.paypal.com"
  end

  def form_submit_path
    "/cgi-bin/webscr"
  end

  def keys
    [
      :cmd, :business, :item_name, :amount, :currency_code, :invoice, :custom, :email, :no_shipping,
      :notify_url, :return, :cancel_return
    ]
  end
end


# Example params POSTed to the return URL (from the PayPal sandbox):
#
# {
#   "transaction_subject"=>"$10.00 test",
#   "txn_type"=>"web_accept",
#   "payment_date"=>"13:29:56 Jul 04, 2013 PDT",
#   "last_name"=>"Crawford",
#   "residence_country"=>"US",
#   "pending_reason"=>"unilateral",
#   "item_name"=>"$10.00 test",
#   "payment_gross"=>"10.00",
#   "mc_currency"=>"USD",
#   "payment_type"=>"instant",
#   "protection_eligibility"=>"Ineligible",
#   "payer_status"=>"verified",
#   "verify_sign"=>"AFcWxV21C7fd0v3bYYYRCpSSRl31Apc0.g4ELJEDPNo3UsAL3j0xi3JL",
#   "tax"=>"0.00",
#   "test_ipn"=>"1",
#   "payer_email"=>"jasonc@alumni.cmu.edu",
#   "txn_id"=>"5DW252222B671151W",
#   "quantity"=>"1",
#   "receiver_email"=>"donations@freeobjectivistbooks.org",
#   "first_name"=>"Jason",
#   "invoice"=>"502e1f61-d41e-42af-a674-45e4dc2cddb2",
#   "payer_id"=>"N4V6TG6NJXWBL",
#   "item_number"=>"",
#   "handling_amount"=>"0.00",
#   "payment_status"=>"Pending",
#   "shipping"=>"0.00",
#   "mc_gross"=>"10.00",
#   "custom"=>"",
#   "charset"=>"windows-1252",
#   "notify_version"=>"3.7",
#   "auth"=>"Aj3IKEcSe0EU3XusAr8R4CTJgUYN5Kw.2OpZSJ62hOJo2jmBPobvjDCQAQ6z.V0iK.otdVW1WpoG4fxZYNFMcgA",
#   "path"=>"contributions/test"
# }
