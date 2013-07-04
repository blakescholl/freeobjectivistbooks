# encoding: UTF-8

require 'test_helper'

class ContributionsControllerTest < ActionController::TestCase
  def setup
    @donor = create :donor
  end

  # Create

  def ipn_params
    {
      "transaction_subject" => "Book 1 to Student 1 in Anytown, USA",
      "txn_type" => "web_accept",
      "payment_date" => Time.now.to_i.to_s,
      "last_name" => @donor.name.words.last,
      "residence_country" => "US",
      "item_name" => "Book 1 to Student 1 in Anytown, USA",
      "payment_gross" => "10.00",
      "mc_currency" => "USD",
      "payment_type" => "instant",
      "protection_eligibility" => "Ineligible",
      "payer_status" => "verified",
      "verify_sign" => "AFcWxV21C7fd0v3bYYYRCpSSRl31Apc0.g4ELJEDPNo3UsAL3j0xi3JL",
      "tax" => "0.00",
      "payer_email" => @donor.email,
      "txn_id" => "5DW252222B671151W",
      "quantity" => "1",
      "receiver_email" => "donations@freeobjectivistbooks.org",
      "first_name" => @donor.name.words.first,
      "invoice" => "502e1f61-d41e-42af-a674-45e4dc2cddb2",
      "payer_id" => "N4V6TG6NJXWBL",
      "item_number" => "",
      "handling_amount" => "0.00",
      "payment_status" => "Created",
      "shipping" => "0.00",
      "mc_gross" => "10.00",
      "custom" => @donor.id.to_s,
      "charset" => "windows-1252",
      "notify_version" => "3.7",
      "auth" => "Aj3IKEcSe0EU3XusAr8R4CTJgUYN5Kw.2OpZSJ62hOJo2jmBPobvjDCQAQ6z.V0iK.otdVW1WpoG4fxZYNFMcgA",
      "path" => "contributions/test",
    }
  end

  test "create" do
    assert_difference "@donor.balance", Money.parse(10) do
      post :create, ipn_params
      assert_response :success
      @donor.reload
    end

    contribution = Contribution.find_by_transaction_id "5DW252222B671151W"
    assert_not_nil contribution
    assert_equal @donor, contribution.user
    assert_equal Money.parse(10), contribution.amount
  end

  test "create for order" do
    donations = create_list :donation, 1, user: @donor
    order = Order.create user: @donor, donations: donations

    assert_difference "@donor.balance", Money.parse(0) do
      post :create, ipn_params.merge(order_id: order.id)
      assert_response :success
      @donor.reload
    end

    contribution = Contribution.find_by_transaction_id "5DW252222B671151W"
    assert_not_nil contribution
    assert_equal @donor, contribution.user
    assert_equal order, contribution.order
    assert_equal Money.parse(10), contribution.amount

    order.reload
    assert order.paid?, "order is not paid"
  end

  test "create is idempotent" do
    post :create, ipn_params
    assert_response :success
    @donor.reload

    assert_difference "@donor.balance", Money.parse(0) do
      post :create, ipn_params
      assert_response :success
      @donor.reload
    end

    assert_equal 1, Contribution.where(transaction_id: "5DW252222B671151W").count
  end

  test "create doesn't create if status is failure" do
    assert_difference "@donor.balance", Money.parse(0) do
      post :create, ipn_params.merge('payment_status' => "Failed")
      assert_response :success
    end

    assert_nil Contribution.find_by_transaction_id "5DW252222B671151W"
  end

  test "create doesn't create from sandbox transactions" do
    assert_difference "@donor.balance", Money.parse(0) do
      post :create, ipn_params.merge('test_ipn' => '1')
      assert_response :success
    end

    assert_nil Contribution.find_by_transaction_id "5DW252222B671151W"
  end

  # Test

  test "test" do
    get :test, params, session_for(@donor)
    assert_response :success
    assert_select 'form'
  end
end
