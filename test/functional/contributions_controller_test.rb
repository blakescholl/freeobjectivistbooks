# encoding: UTF-8

require 'test_helper'

class ContributionsControllerTest < ActionController::TestCase
  def setup
    @donor = create :send_money_donor
  end

  # New

  test "new" do
    donations = create_list :donation, 2, user: @donor

    get :new, params, session_for(@donor)
    assert_response :success

    assert_select 'h1', "Your donations"
    assert_select 'li', text: /Book \d+ to Student \d+ in Anytown, USA –\s+\$10/, count: 2
    assert_select 'p', /Total for your donations: \$20/
    assert_select 'form'
  end

  test "new with no donations" do
    get :new, params, session_for(@donor)
    assert_response :success

    assert_select 'h1', "Your donations"
    assert_select 'li', false
    assert_select 'form', false
    assert_select 'p', /No donations/
    assert_select 'a', /Find students/
  end

  test "new with no donations in send-books mode" do
    donor2 = create :send_books_donor

    get :new, params, session_for(donor2)
    assert_response :success

    assert_select 'h1', "Your donations"
    assert_select 'li', false
    assert_select 'form', false
    assert_select 'p', /Your account is set up to send books directly/
  end

  test "new shows warning to Chrome users" do
    donation = create :donation, user: @donor

    @request.user_agent = user_agent_for :chrome
    get :new, params, session_for(@donor)
    assert_response :success
    assert_select '.error .headline', /Chrome/
  end

  test "new doesn't show warning to Safari users" do
    donation = create :donation, user: @donor

    @request.user_agent = user_agent_for :safari
    get :new, params, session_for(@donor)
    assert_response :success
    assert_select '.error .headline', false
  end

  # Create

  def amazon_ipn_params
    {
      "paymentReason" => "Book 1 to Student 1 in Anytown, USA",
      "signatureMethod"=>"RSA-SHA1",
      "transactionAmount" => "USD 10.000000",
      "transactionId" => "17J3JCDIN2HZCSKGTCIVOJ1MB81RGOIEV5P",
      "status" => "PS",
      "buyerEmail" => @donor.email,
      "referenceId" => @donor.id.to_s,
      "recipientEmail" => "donations@freeobjectivistbooks.org",
      "transactionDate" => Time.now.to_i.to_s,
      "buyerName" => @donor.name,
      "operation" => "pay",
      "recipientName" => "Free Objectivist Books",
      "signatureVersion" => "2",
      "certificateUrl" => "https://fps.amazonaws.com/certs/090911/PKICert.pem?requestId=15n8r3d",
      "paymentMethod" => "CC",
      "signature" => "Oe9T3lr4BQTeMbyCior55XoySQKdB7q0dnnI6ZypUJQKzisMFAwSSgjEHg7Kr/QvlN2se99xXea8",
    }
  end

  test "create" do
    assert_difference "@donor.balance", Money.parse(10) do
      post :create, amazon_ipn_params
      assert_response :success
      @donor.reload
    end

    contribution = Contribution.find_by_transaction_id "17J3JCDIN2HZCSKGTCIVOJ1MB81RGOIEV5P"
    assert_not_nil contribution
    assert_equal @donor, contribution.user
    assert_equal Money.parse(10), contribution.amount
  end

  test "create for order" do
    donations = create_list :donation, 1, user: @donor
    order = Order.create user: @donor, donations: donations

    assert_difference "@donor.balance", Money.parse(0) do
      post :create, amazon_ipn_params.merge(order_id: order.id)
      assert_response :success
      @donor.reload
    end

    contribution = Contribution.find_by_transaction_id "17J3JCDIN2HZCSKGTCIVOJ1MB81RGOIEV5P"
    assert_not_nil contribution
    assert_equal @donor, contribution.user
    assert_equal order, contribution.order
    assert_equal Money.parse(10), contribution.amount

    order.reload
    assert order.paid?, "order is not paid"
  end

  test "create is idempotent" do
    post :create, amazon_ipn_params
    assert_response :success
    @donor.reload

    assert_difference "@donor.balance", Money.parse(0) do
      post :create, amazon_ipn_params
      assert_response :success
      @donor.reload
    end

    assert_equal 1, Contribution.where(transaction_id: "17J3JCDIN2HZCSKGTCIVOJ1MB81RGOIEV5P").count
  end

  test "create doesn't create if status is failure" do
    assert_difference "@donor.balance", Money.parse(0) do
      post :create, amazon_ipn_params.merge('status' => "PF")
      assert_response :success
    end

    assert_nil Contribution.find_by_transaction_id "17J3JCDIN2HZCSKGTCIVOJ1MB81RGOIEV5P"
  end

  test "create doesn't create from sandbox transactions" do
    certificate_url = "https://fps.sandbox.amazonaws.com/certs/090911/PKICert.pem?requestId=15n8r3d"
    assert_difference "@donor.balance", Money.parse(0) do
      post :create, amazon_ipn_params.merge('certificateUrl' => certificate_url)
      assert_response :success
    end

    assert_nil Contribution.find_by_transaction_id "17J3JCDIN2HZCSKGTCIVOJ1MB81RGOIEV5P"
  end

  # Thank-you

  test "thankyou" do
    get :thankyou, amazon_ipn_params, session_for(@donor)
    assert_response :success
    assert_select 'h1', "Thank you"
    assert_select 'p', /Thank you/
    assert_select 'a', /Find more/
  end

  test "thankyou for failed payment" do
    get :thankyou, amazon_ipn_params.merge('status' => "PF"), session_for(@donor)
    assert_redirected_to action: :new
  end

  # Cancel

  test "cancel" do
    donations = create_list :donation, 2, user: @donor

    get :new, {abandoned: true}, session_for(@donor)
    assert_response :success

    assert_select 'h1', "Your donations"
    assert_select 'li', 2
    assert_select 'form'
    assert_select '.error .headline', /canceled/
  end

  # Test

  test "test" do
    get :test, params, session_for(@donor)
    assert_response :success
    assert_select 'form'
  end
end
