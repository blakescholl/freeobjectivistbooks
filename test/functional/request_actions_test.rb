require 'test_helper'

class RequestActionsTest < ActionController::TestCase
  tests RequestsController

  # Add/update address

  def verify_address_link(which)
    verify_link 'add your address', (which == :add)
    verify_link 'update shipping', (which == :update)
  end

  test "add address link if no address" do
    request = create :request_no_address
    get :show, {id: request.id}, session_for(request.user)
    assert_response :success
    verify_address_link :add
  end

  test "update address link for open request" do
    request = create :request
    get :show, {id: request.id}, session_for(request.user)
    assert_response :success
    verify_address_link :update
  end

  test "update address link for granted request" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_address_link :update
  end

  test "no address link for sent request" do
    donation = create :donation, status: 'sent'
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_address_link :none
  end

  test "no address link for donor" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_address_link :none
  end

  test "no address link for fulfiller" do
    fulfillment = create :fulfillment
    get :show, {id: fulfillment.request.id}, session_for(fulfillment.user)
    assert_response :success
    verify_address_link :none
  end

  # Flag

  def verify_flag_link(present = true)
    verify_link 'flag', present
  end

  test "flag link for donor" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_flag_link
  end

  test "flag link for fulfiller" do
    fulfillment = create :fulfillment
    get :show, {id: fulfillment.request.id}, session_for(fulfillment.user)
    assert_response :success
    verify_flag_link
  end

  test "no flag link for sent request" do
    donation = create :donation, status: 'sent'
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_flag_link false
  end

  test "no flag link for flagged request" do
    donation = create :donation
    donation.flag!
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_flag_link false
  end

  test "no flag link for paid donor" do
    donation = create :donation, :paid
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_flag_link false
  end

  test "no flag link for student" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_flag_link false
  end

  # Amazon link

  def verify_amazon_link(present = true)
    verify_link 'Amazon', present
  end

  test "amazon link for send-books donor" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_amazon_link
  end

  test "amazon link for fulfiller" do
    fulfillment = create :fulfillment
    get :show, {id: fulfillment.request.id}, session_for(fulfillment.user)
    assert_response :success
    verify_amazon_link
  end

  test "no amazon link for already-sent book" do
    donation = create :donation, status: 'sent'
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_amazon_link false
  end

  test "no amazon link for book with no ASIN" do
    donation = create :donation_for_request_not_amazon
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_amazon_link false
  end

  test "no amazon link for paid donor" do
    donation = create :donation, :paid
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_amazon_link false
  end

  test "no amazon link for student" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_amazon_link false
  end

  # Sent button

  def verify_sent_button(present = true)
    if present
      assert_select '.sidebar h2', /Update/
      assert_select '.sidebar form', present
    end
    assert_select '.sidebar p', text: /Let Student \d+ know when you have sent/, count: (present ? 1 : 0)
  end

  test "sent button for donor" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_sent_button
  end

  test "sent button for fulfiller" do
    fulfillment = create :fulfillment
    get :show, {id: fulfillment.request.id}, session_for(fulfillment.user)
    assert_response :success
    verify_sent_button
  end

  test "no sent button for sent request" do
    donation = create :donation, status: 'sent'
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_sent_button false
  end

  test "no sent button for send-money donor" do
    donation = create :donation, :paid
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_sent_button false
  end

  test "no sent button for student" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_sent_button false
  end

  # Thank

  def verify_thank_link(present = true)
    verify_link 'thank', present
  end

  test "no thank link on open request" do
    request = create :request
    get :show, {id: request.id}, session_for(request.user)
    assert_response :success
    verify_thank_link false
  end

  test "thank link on granted request" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_thank_link
  end

  test "no thank link on thanked request" do
    donation = create :donation, thanked: true
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_thank_link false
  end

  test "no thank link for donor" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_thank_link false
  end

  test "no thank link for fulfiller" do
    fulfillment = create :fulfillment
    get :show, {id: fulfillment.request.id}, session_for(fulfillment.user)
    assert_response :success
    verify_thank_link false
  end

  # Received button

  def verify_received_button(present = true)
    if present
      assert_select '.sidebar h2', /Update/
    end
    assert_select '.sidebar p', text: /Let Donor \d+ know when you have received/, count: (present ? 1 : 0)
  end

  test "no received button for open request" do
    request = create :request
    get :show, {id: request.id}, session_for(request.user)
    assert_response :success
    verify_received_button false
  end

  test "received button" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_received_button
  end

  test "no received button if already received" do
    donation = create :donation, status: 'received'
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_received_button false
  end

  test "no received button for donor" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_received_button false
  end

  test "no received button for fulfiller" do
    fulfillment = create :fulfillment
    get :show, {id: fulfillment.request.id}, session_for(fulfillment.user)
    assert_response :success
    verify_received_button false
  end

  # Read button

  def verify_read_button(present = true)
    if present
      assert_select '.sidebar h2', /Update/
    end
    assert_select '.sidebar p', text: /Let Donor \d+ know when you have finished reading/, count: (present ? 1 : 0)
  end

  test "no read button for unreceived request" do
    donation = create :donation, status: 'sent'
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_read_button false
  end

  test "read button" do
    donation = create :donation, status: 'received'
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_read_button
  end

  test "no read button if already read" do
    donation = create :donation, status: 'read'
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_read_button false
  end

  test "no read button for donor" do
    donation = create :donation, status: 'received'
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_read_button false
  end

  test "no read button for fulfiller" do
    fulfillment = create :fulfillment
    fulfillment.donation.receive!
    get :show, {id: fulfillment.request.id}, session_for(fulfillment.user)
    assert_response :success
    verify_read_button false
  end

  # Cancel donation

  def verify_cancel_donation_link(present = true)
    verify_link 'cancel this donation', present
  end

  test "cancel donation link for send-books donor" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_cancel_donation_link
  end

  test "cancel donation link for send-money donor" do
    donation = create :donation_with_send_money_donor
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_cancel_donation_link
  end

  test "no cancel donation link if received" do
    donation = create :donation, status: 'received'
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_cancel_donation_link false
  end

  test "no cancel donation link if paid" do
    donation = create :donation_with_send_money_donor, paid: true
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_cancel_donation_link false
  end

  test "no cancel donation link for student" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_cancel_donation_link false
  end

  test "no cancel donation link for fulfiller" do
    fulfillment = create :fulfillment
    get :show, {id: fulfillment.request.id}, session_for(fulfillment.user)
    assert_response :success
    verify_cancel_donation_link false
  end

  # Cancel request

  def verify_cancel_request_link(present = true)
    verify_link 'cancel this request', present
  end

  test "cancel request link on open request" do
    request = create :request
    get :show, {id: request.id}, session_for(request.user)
    assert_response :success
    verify_cancel_request_link
  end

  test "cancel request link on granted request" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_cancel_request_link
  end

  test "no cancel request link on canceled request" do
    request = create :request, :canceled
    get :show, {id: request.id}, session_for(request.user)
    assert_response :success
    verify_cancel_request_link false
  end

  test "no cancel request link on sent request" do
    donation = create :donation, status: 'sent'
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_cancel_request_link false
  end

  test "no cancel request link for donor" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_cancel_request_link false
  end

  test "no cancel request link for fulfiller" do
    fulfillment = create :fulfillment
    get :show, {id: fulfillment.request.id}, session_for(fulfillment.user)
    assert_response :success
    verify_cancel_request_link false
  end

  # Not received

  def verify_not_received_link(present = true)
    verify_link 'report book not received', present
  end

  test "no not-received link on open request" do
    request = create :request
    get :show, {id: request.id}, session_for(request.user)
    assert_response :success
    verify_not_received_link false
  end

  test "not-received link on granted request" do
    donation = create :donation, created_at: 30.days.ago
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_not_received_link
  end

  test "not-received link on recently granted request" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_not_received_link false
  end

  test "no not-received link on sent request" do
    donation = create :donation, created_at: 30.days.ago, status: 'sent'
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_not_received_link false
  end

  test "no not-received link on flagged request" do
    donation = create :donation, created_at: 30.days.ago, flagged: true
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_not_received_link false
  end

  test "no not-received link on send-money request" do
    donation = create :donation_with_send_money_donor, created_at: 30.days.ago
    get :show, {id: donation.request.id}, session_for(donation.student)
    assert_response :success
    verify_not_received_link false
  end

  test "no not-received link for donor" do
    donation = create :donation
    get :show, {id: donation.request.id}, session_for(donation.user)
    assert_response :success
    verify_not_received_link false
  end

  test "no not-received link for fulfiller" do
    fulfillment = create :fulfillment
    get :show, {id: fulfillment.request.id}, session_for(fulfillment.user)
    assert_response :success
    verify_not_received_link false
  end

  # Renew

  def verify_renew_link(type)
    verify_link 'reopen', (type == :reopen)
    verify_link 'renew', (type == :renew)
  end

  test "no renew link on recent open request" do
    request = create :request
    get :show, {id: request.id}, session_for(request.user)
    assert_response :success
    verify_renew_link :none
  end

  test "renew link on old request" do
    request = create :request, :renewable
    get :show, {id: request.id}, session_for(request.user)
    assert_response :success
    verify_renew_link :renew
  end

  test "reopen link on canceled request" do
    request = create :request, :canceled
    get :show, {id: request.id}, session_for(request.user)
    assert_response :success
    verify_renew_link :reopen
  end

  test "no reopen link if other open requests" do
    request = create :request, :canceled
    request2 = create :request, user: request.user
    get :show, {id: request.id}, session_for(request.user)
    assert_response :success
    verify_renew_link :none
  end

  test "no renew link on granted request" do
    request = create :request, :renewable
    donation = create :donation, request: request
    get :show, {id: request.id}, session_for(request.user)
    assert_response :success
    verify_renew_link :none
  end
end
