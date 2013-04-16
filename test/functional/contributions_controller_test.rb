# encoding: UTF-8

require 'test_helper'

class ContributionsControllerTest < ActionController::TestCase
  def setup
    @donor = create :donor
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

  # Test

  test "test" do
    get :test, params, session_for(@donor)
    assert_response :success
    assert_select 'form'
  end
end
