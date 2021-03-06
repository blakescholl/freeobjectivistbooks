require 'test_helper'

class DonationTest < ActiveSupport::TestCase
  # Associations

  test "request" do
    assert_equal @quentin_request, @quentin_donation.request
  end

  test "user" do
    assert_equal @hugh, @quentin_donation.user
  end

  test "events" do
    events = @quentin_donation.events
    assert !events.empty?
    events.each {|event| assert_equal @quentin_donation, event.donation}
  end

  test "review" do
    assert_nil @hank_donation_received.review
    assert_equal @quentin_review, @quentin_donation_read.review
  end

  test "reminders" do
    assert_equal [@cameron_reminder], @hank_donation.reminders
    assert_equal [@cameron_reminder], @hank_donation_received.reminders
    assert_equal [], @quentin_donation.reminders
  end

  # Scopes

  def verify_scope(scope)
    super Donation, scope
  end

  test "active" do
    verify_scope(:active) {|donation| donation.active?}
  end

  test "canceled" do
    verify_scope(:canceled) {|donation| donation.canceled?}
  end

  test "thanked" do
    verify_scope(:thanked) {|donation| donation.active? && donation.thanked?}
  end

  test "not thanked" do
    verify_scope(:not_thanked) {|donation| donation.active? && !donation.thanked?}
  end

  test "flagged" do
    verify_scope(:flagged) {|donation| donation.active? && donation.flagged?}
  end

  test "not flagged" do
    verify_scope(:not_flagged) {|donation| donation.active? && !donation.flagged?}
  end

  test "paid" do
    verify_scope(:paid) {|donation| donation.paid?}
  end

  test "unpaid" do
    verify_scope(:unpaid) {|donation| !donation.paid?}
  end

  test "has price" do
    verify_scope(:has_price) {|donation| donation.price.present?}
  end

  test "fulfilled" do
    @frisco_donation.fulfill @kira
    verify_scope(:fulfilled) {|donation| donation.fulfilled?}
  end

  test "unfulfilled" do
    verify_scope(:unfulfilled) {|donation| !donation.fulfilled?}
  end

  test "not sent" do
    verify_scope(:not_sent) {|donation| donation.active? && !donation.sent?}
  end

  test "sent" do
    verify_scope(:sent) {|donation| donation.active? && donation.sent?}
  end

  test "in transit" do
    verify_scope(:in_transit) {|donation| donation.active? && donation.sent? && !donation.received?}
  end

  test "received" do
    verify_scope(:received) {|donation| donation.active? && donation.received?}
  end

  test "reading" do
    verify_scope(:reading) {|donation| donation.active? && donation.received? && !donation.read?}
  end

  test "read" do
    verify_scope(:read) {|donation| donation.active? && donation.read?}
  end

  test "needs sending" do
    verify_scope(:needs_sending) {|donation| donation.active? && donation.needs_sending?}
  end

  test "needs fix" do
    verify_scope(:needs_fix) {|donation| donation.needs_fix?}
  end

  test "needs fulfillment" do
    verify_scope(:needs_fulfillment) do |donation|
      donation.active? && donation.needs_sending? && donation.paid? && !donation.fulfilled?
    end
  end

  test "needs fulfillment scope excludes fulfilled donations" do
    assert Donation.needs_fulfillment.include?(@frisco_donation)
    @frisco_donation.fulfill @kira
    assert !Donation.needs_fulfillment.include?(@frisco_donation)
  end

  test "needs donor action" do
    verify_scope(:needs_donor_action) {|donation| donation.needs_donor_action?}
  end

  test "no donor action" do
    verify_scope(:no_donor_action) {|donation| !donation.needs_donor_action?}
  end

  test "flagged too long" do
    verify_scope(:flagged_too_long) {|donation| donation.needs_fix? && donation.request.can_autocancel?}
  end

  # Callbacks

  test "default status is not_sent" do
    donation = @howard_request.donations.create user: @hugh
    assert_equal "not_sent", donation.status
    assert_equal donation.created_at, donation.status_updated_at
  end

  # Derived attributes

  test "student" do
    assert_equal @dagny, @dagny_donation.student
  end

  test "book" do
    assert_equal @atlas, @hank_donation.book
  end

  test "address" do
    assert_equal @hank.address, @hank_donation.address
  end

  test "sent?" do
    assert !@dagny_donation.sent?
    assert @quentin_donation.sent?
    assert @hank_donation_received.sent?
  end

  test "sent at" do
    assert_nil @dagny_donation.sent_at
    assert_equal events(:hugh_updates_quentin).happened_at, @quentin_donation.sent_at
    assert_equal events(:cameron_updates_hank).happened_at, @hank_donation_received.sent_at
  end

  test "in transit?" do
    assert !@dagny_donation.in_transit?
    assert @quentin_donation.in_transit?
    assert !@hank_donation_received.in_transit?
  end

  test "received?" do
    assert !@dagny_donation.received?
    assert !@quentin_donation.received?
    assert @hank_donation_received.received?
    assert @quentin_donation_read.received?
  end

  test "reading?" do
    assert !@quentin_donation.reading?
    assert @hank_donation_received.reading?
    assert !@quentin_donation_read.reading?
  end

  test "read?" do
    assert !@quentin_donation.read?
    assert !@hank_donation_received.read?
    assert @quentin_donation_read.read?
  end

  test "needs fix?" do
    assert @dagny_donation.needs_fix?
    assert !@quentin_donation.needs_fix?
    assert !@dagny_donation_canceled.needs_fix?
  end

  test "needs sending?" do
    assert @quentin_donation_unsent.needs_sending?
    assert !@dagny_donation.needs_sending?    # flagged
    assert !@quentin_donation.needs_sending?  # already sent
  end

  test "can send?" do
    assert @quentin_donation_unsent.can_send?
    assert @dagny_donation.can_send?     # flagged
    assert !@quentin_donation.can_send?  # already sent
  end

  test "can flag?" do
    assert @quentin_donation_unsent.can_flag?, "can't flag unsent donation"
    assert !@quentin_donation.can_flag?, "can flag already-sent donation"
    assert !@dagny_donation.can_flag?, "can flag already-flagged donation"
  end

  # Can send money

  test "can send money?" do
    donation = build :donation
    assert donation.can_send_money?
  end

  test "can send money? false if book has no price" do
    donation = build :donation_for_request_not_amazon
    assert !donation.can_send_money?
  end

  test "can send money? false if student is foreign" do
    donation = build :donation_for_request_foreign_student
    assert !donation.can_send_money?
  end

  # Can cancel

  test "donor can cancel?" do
    assert @hank_donation.donor_can_cancel?
    assert @quentin_donation.donor_can_cancel?
    assert !@hank_donation_received.donor_can_cancel? # already received
    assert !@frisco_donation.donor_can_cancel?        # already paid for
  end

  test "student can cancel?" do
    assert @quentin_donation_unsent.student_can_cancel?
  end

  test "student can't cancel if sent" do
    event = @quentin_donation_unsent.update_status status: "sent"
    @quentin_donation_unsent.save! && event.save!
    assert !@quentin_donation_unsent.student_can_cancel?
  end

  test "student can't cancel if flagged" do
    flag = create :flag
    assert !flag.donation.student_can_cancel?
  end

  test "student can't cancel if new" do
    @quentin_donation_unsent.created_at = Time.now
    @quentin_donation_unsent.save!
    assert !@quentin_donation_unsent.student_can_cancel?
  end

  test "student can't cancel if paid" do
    donation = build :donation, :paid
    assert !donation.student_can_cancel?
  end

  test "can cancel?" do
    assert @hank_donation.can_cancel?(@cameron)
    assert !@hank_donation.can_cancel?(@hank)
    assert !@hank_donation.can_cancel?(@quentin)

    assert !@hank_donation_received.can_cancel?(@cameron)
    assert !@hank_donation_received.can_cancel?(@hank)
    assert !@hank_donation_received.can_cancel?(@quentin)

    assert @quentin_donation_unsent.can_cancel?(@quentin)
    assert @quentin_donation_unsent.can_cancel?(@hugh)
    assert !@quentin_donation_unsent.can_cancel?(@dagny)
  end

  # Create

  test "price recorded on create" do
    @howard_request.grant! @cameron
    @howard_request.reload
    assert_equal @atlas.price, @howard_request.donation.price
  end

  test "pledge recorded on create" do
    pledge = create :pledge
    request = create :request

    request.grant! pledge.user
    assert_equal pledge, request.donation.pledge
  end

  # Cancel

  test "cancel by donor" do
    event = @hank_donation.cancel({event: {message: "Sorry"}}, @cameron)
    assert @hank_donation.canceled?, "donation not canceled"

    assert_equal "cancel_donation", event.type
    assert_nil event.detail
    assert_equal @hank_request, event.request
    assert_equal @cameron, event.user
    assert_equal @cameron, event.donor
    assert_equal "Sorry", event.message
    assert_not_nil event.happened_at
    assert_open_at_is_recent @hank_donation.request
  end

  test "cancel by student" do
    event = @quentin_donation_unsent.cancel({event: {detail: "not_received"}}, @quentin)
    assert @quentin_donation_unsent.canceled?, "donation not canceled"

    assert_equal "cancel_donation", event.type
    assert_equal "not_received", event.detail
    assert_equal @quentin_request_unsent, event.request
    assert_equal @quentin, event.user
    assert_equal @hugh, event.donor
    assert_nil event.message
    assert_not_nil event.happened_at
    assert_open_at_is_recent @quentin_donation_unsent.request
  end

  test "cancel raises exception if can't cancel" do
    assert_raise RuntimeError do
      @hank_donation_received.cancel({event: {message: "Sorry"}}, @cameron)
    end

    assert_raise RuntimeError do
      @dagny_donation.cancel({event: {detail: "not_received"}}, @dagny)
    end
  end

  # Update status

  test "update status sent" do
    time = Time.now
    event = @quentin_donation_unsent.update_status status: "sent"

    assert @quentin_donation_unsent.sent?
    assert @quentin_donation_unsent.status_updated_at >= time

    assert_equal @quentin_donation_unsent, event.donation
    assert_equal @quentin_request_unsent, event.request
    assert_equal @hugh, event.user
    assert_equal @hugh, event.donor
    assert_equal "update_status", event.type
    assert_equal "sent", event.detail
    assert_nil event.message
    assert_not_nil event.happened_at
  end

  test "update status sent when flagged" do
    time = Time.now
    event = @dagny_donation.update_status status: "sent"

    assert @dagny_donation.sent?
    assert @dagny_donation.status_updated_at >= time
    assert !@dagny_donation.flagged?

    assert_equal @dagny_donation, event.donation
    assert_equal @dagny_request, event.request
    assert_equal @hugh, event.user
    assert_equal @hugh, event.donor
    assert_equal "update_status", event.type
    assert_equal "sent", event.detail
    assert_nil event.message
    assert_not_nil event.happened_at
  end

  test "update status received" do
    time = Time.now
    event = @dagny_donation.update_status status: "received", event: {message: "I got it"}

    assert @dagny_donation.received?
    assert @dagny_donation.status_updated_at >= time

    assert_equal @dagny_donation, event.donation
    assert_equal @dagny_request, event.request
    assert_equal @dagny, event.user
    assert_equal @hugh, event.donor
    assert_equal "update_status", event.type
    assert_equal "received", event.detail
    assert_equal "I got it", event.message
    assert !event.is_thanks?
    assert_not_nil event.happened_at
  end

  test "update status received with thank-you" do
    event = @quentin_donation.update_status status: "received", event: {message: "Thanks!", is_thanks: true, public: false}
    assert @quentin_donation.received?

    assert_equal @quentin_donation, event.donation
    assert_equal @quentin_request, event.request
    assert_equal @quentin, event.user
    assert_equal @hugh, event.donor
    assert_equal "update_status", event.type
    assert_equal "received", event.detail
    assert_equal "Thanks!", event.message
    assert event.is_thanks?
    assert !event.public?
    assert_not_nil event.happened_at
  end

  test "update status received with empty thank-you" do
    event = @quentin_donation.update_status status: "received", event: {message: "", is_thanks: true, public: false}
    assert @quentin_donation.received?

    assert_equal @quentin_donation, event.donation
    assert_equal @quentin_request, event.request
    assert_equal @quentin, event.user
    assert_equal @hugh, event.donor
    assert_equal "update_status", event.type
    assert_equal "received", event.detail
    assert !event.is_thanks?
    assert_nil event.public
    assert_not_nil event.happened_at
  end

  test "update status read" do
    time = Time.now
    event = @hank_donation_received.update_status status: "read"

    assert @hank_donation_received.read?
    assert @hank_donation_received.status_updated_at >= time

    assert_equal @hank, event.user
    assert_equal "update_status", event.type
    assert_equal "read", event.detail
  end

  # Flag

  test "flag" do
    event = @quentin_donation.add_flag message: "Is this address correct?"
    assert @quentin_donation.flagged?
    assert_equal "flag", event.type
    assert_equal "Is this address correct?", @quentin_donation.flag.message
  end
end
