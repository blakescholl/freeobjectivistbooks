class PaypalSignature
  def initialize(params, post)
    @params = params
    @post = post
  end

  def valid?
    response = make_verification_request
    response == "VERIFIED"
  end

  def sandbox?
    @params['test_ipn'].to_bool
  end

private
  def make_verification_request
    url = verification_url
    Rails.logger.info "verifying PayPal IPN at #{url}"
    uri = URI.parse url

    client = Net::HTTP.new uri.host, uri.port
    client.use_ssl = true
    client.verify_mode = OpenSSL::SSL::VERIFY_PEER
    client.verify_depth = 5

    response = client.start do |client|
      request = Net::HTTP::Get.new url
      client.request request
    end

    Rails.logger.info "PayPal verification response: #{response.body}"
    response.body
  end

  def verification_url
    payment = PaypalPayment.new is_live: !sandbox?
    base_url = payment.form_submit_url
    "#{base_url}?cmd=_notify-validate&#{@post}"
  end
end
