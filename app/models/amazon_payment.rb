# Represents a payment to be made through Amazon Simple Pay:
# http://docs.aws.amazon.com/AmazonSimplePay/latest/ASPAdvancedUserGuide/Welcome.html
#
# Relies on aws_access_key and aws_secret_key being set in Rails.application.config. It will hit
# the live payments environment if aws_payments_live is true; otherwise it will use the sandbox.
class AmazonPayment
  attr_reader :reference_id, :amount, :description
  attr_reader :is_donation_widget, :collect_shipping_address, :process_immediate, :immediate_return, :cobranding_style
  attr_reader :ipn_url, :return_url, :abandon_url
  attr_reader :signature_method

  def initialize(attributes = {})
    @is_donation_widget = 0
    @collect_shipping_address = 0
    @process_immediate = 1
    @immediate_return = 0
    @cobranding_style = "logo"
    @signature_method = "HmacSHA256"

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
    unsigned_params.merge(signature: signature)
  end

private

  def access_key
    Rails.application.config.aws_access_key
  end

  def form_submit_host
    payments = Rails.application.config.aws_payments_live ? "payments" : "payments-sandbox"
    "authorize.#{payments}.amazon.com"
  end

  def form_submit_path
    "/pba/paypipeline"
  end

  def signature_version
    2
  end

  def keys
    [
      :reference_id, :amount, :description,
      :is_donation_widget, :collect_shipping_address, :process_immediate, :immediate_return, :cobranding_style,
      :ipn_url, :return_url, :abandon_url,
      :access_key, :signature_method, :signature_version,
    ]
  end

  def unsigned_params
    keys.inject({}) do |hash,key|
      camelkey = key.to_s.camelcase :lower
      value = send key
      hash.merge(camelkey => value)
    end
  end

  def urlencode(string)
    CGI.escape(string.to_s).gsub("+", "%20").gsub("%7E", "~")
  end

  def canonical_param_string
    hash = unsigned_params
    keys = hash.keys.sort
    pairs = keys.map {|key| urlencode(key) + "=" + urlencode(hash[key])}
    pairs.join "&"
  end

  def canonical_request_string
    host = form_submit_host.downcase
    path = form_submit_path.present? ? form_submit_path : "/"
    path = urlencode(path).gsub("%2F", "/")
    parts = ["POST", host, path, canonical_param_string]
    parts.join "\n"
  end

  def digest
    case signature_method
    when "HmacSHA1" then OpenSSL::Digest::SHA1.new
    when "HmacSHA256" then OpenSSL::Digest::SHA256.new
    else raise "Unknown/unsupported AWS signature method #{signature_method}"
    end
  end

  # Generates a signature for the payment request based on this algorithm:
  # http://docs.aws.amazon.com/AmazonSimplePay/latest/ASPAdvancedUserGuide/Sig2CreateSignature.html
  def signature
    secret = Rails.application.config.aws_secret_key
    hmac = OpenSSL::HMAC.digest digest, secret, canonical_request_string
    Base64.encode64(hmac).chomp
  end
end
