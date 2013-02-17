require 'rexml/document'

class AmazonSignature
  def initialize(params, url_endpoint)
    @params = params
    @url_endpoint = url_endpoint
  end

  def valid?
    return false if !certificate_url_valid?
    response = make_verification_request
    status = response.elements['VerifySignatureResponse/VerifySignatureResult/VerificationStatus']
    status && status.text == "Success"
  end

  def sandbox?
    certificate_url.starts_with? SANDBOX_CERTIFICATE_URL_ROOT
  end

private
  CERTIFICATE_URL_ROOT = "https://fps.amazonaws.com/"
  SANDBOX_CERTIFICATE_URL_ROOT = "https://fps.sandbox.amazonaws.com/"
  USER_AGENT_STRING = "ASPStandard-RUBY-2.0-2010-09-13"

  def certificate_url
    @params['certificateUrl']
  end

  def certificate_url_valid?
    certificate_url.starts_with?(CERTIFICATE_URL_ROOT) || certificate_url.starts_with?(SANDBOX_CERTIFICATE_URL_ROOT)
  end

  def make_verification_request
    url = verification_url
    uri = URI.parse url

    client = Net::HTTP.new uri.host, uri.port
    client.use_ssl = true
    client.ca_file = 'ca-bundle.crt'
    client.verify_mode = OpenSSL::SSL::VERIFY_PEER
    client.verify_depth = 5

    response = client.start do |client|
      request = Net::HTTP::Get.new url, {"User-Agent" => USER_AGENT_STRING}
      client.request request
    end

    REXML::Document.new response.body
  end

  def verification_url
    base_url = sandbox? ? SANDBOX_CERTIFICATE_URL_ROOT : CERTIFICATE_URL_ROOT
    params = {
      "Action" => "VerifySignature",
      "UrlEndPoint" => @url_endpoint,
      "Version" => "2008-09-17",
      "HttpParameters" => @params.to_query_string
    }
    base_url + "?" + params.to_query_string
  end
end
