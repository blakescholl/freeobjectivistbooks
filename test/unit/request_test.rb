require 'test_helper'

class RequestTest < ActiveSupport::TestCase
  def reason
    "I've heard so much about this... can't wait to find out who is John Galt!"
  end

  # Creating

  test "new" do
    request = User.new.requests.build
    assert_equal "Atlas Shrugged", request.book
  end

  test "build" do
    request = @howard.requests.build book: "Atlas Shrugged", other_book: "", reason: reason, pledge: "1"
    assert request.valid?, request.errors.inspect
    assert_equal "Atlas Shrugged", request.book
  end

  test "other book" do
    request = @howard.requests.build book: "other", other_book: "Ulysses", reason: reason, pledge: "1"
    assert request.valid?, request.errors.inspect
    assert_equal "Ulysses", request.book
  end

  test "reason is required" do
    request = @howard.requests.build book: "Atlas Shrugged", other_book: "", reason: "", pledge: "1"
    assert request.invalid?
  end

  test "pledge is required" do
    request = @howard.requests.build book: "Atlas Shrugged", other_book: "", reason: reason
    assert request.invalid?
  end

  # Associations

  test "user" do
    assert_equal @howard, @howard_request.user
  end

  test "donor" do
    assert_nil @howard_request.donor
    assert_equal @hugh, @quentin_request.donor
  end

  test "donation" do
    assert_equal donations(:hugh_grants_quentin_wants_vos), @quentin_request.donation
    assert_nil requests(:quentin_wants_opar).donation
  end

  test "donations" do
    assert_equal [donations(:hugh_grants_quentin_wants_vos)], @quentin_request.donations
    assert_equal [donations(:stadler_grants_quentin_wants_opar)], requests(:quentin_wants_opar).donations
  end

  test "referral" do
    assert_equal @email_referral, @hank_request.referral
    assert_nil @hank_request_received.referral
  end

  # Scopes

  def verify_scope(scope)
    super Request, scope
  end

  test "active" do
    verify_scope(:active) {|request| request.active?}
  end

  test "canceled" do
    verify_scope(:canceled) {|request| request.canceled?}
  end

  test "granted" do
    verify_scope(:granted) {|request| request.granted?}
  end

  test "not granted" do
    verify_scope(:not_granted) {|request| request.open?}
  end

  # Derived attributes

  test "active?" do
    assert @quentin_request.active?
    assert !@howard_request_canceled.active?
  end

  test "address" do
    assert_equal @quentin.address, @quentin_request.address
  end

  test "granted?" do
    assert !@howard_request.granted?
    assert @quentin_request.granted?
  end

  test "needs thanks?" do
    assert !@howard_request.needs_thanks?
    assert @quentin_request.needs_thanks?
    assert !@dagny_request.needs_thanks?
  end

  test "sent?" do
    assert !@howard_request.sent?
    assert !@dagny_request.sent?
    assert @quentin_request.sent?
    assert @hank_request_received.sent?
  end

  test "in transit?" do
    assert !@howard_request.in_transit?
    assert !@dagny_request.in_transit?
    assert @quentin_request.in_transit?
    assert !@hank_request_received.in_transit?
  end

  test "received?" do
    assert !@howard_request.received?
    assert !@dagny_request.received?
    assert !@quentin_request.received?
    assert @hank_request_received.received?
    assert @quentin_request_read.received?
  end

  test "reading?" do
    assert !@howard_request.reading?
    assert !@quentin_request.reading?
    assert @hank_request_received.reading?
    assert !@quentin_request_read.reading?
  end

  test "read?" do
    assert !@howard_request.read?
    assert !@quentin_request.read?
    assert !@hank_request_received.read?
    assert @quentin_request_read.read?
  end

  test "flag message" do
    assert_equal "Please add your full name and address", @dagny_request.flag_message
  end

  test "review" do
    assert_nil @howard_request.review
    assert_nil @hank_request_received.review
    assert_equal @quentin_review, @quentin_request_read.review
  end

  test "can update?" do
    assert @howard_request.can_update?            # open
    assert @quentin_request_unsent.can_update?    # not sent
    assert !@quentin_request.can_update?          # sent
    assert !@howard_request_canceled.can_update?  # canceled
  end

  test "can cancel?" do
    assert @howard_request.can_cancel?            # open
    assert @quentin_request_unsent.can_cancel?    # not sent
    assert !@quentin_request.can_cancel?          # sent
    assert !@howard_request_canceled.can_cancel?  # already canceled
  end

  # Grant

  test "grant" do
    request = @quentin_request_open
    event = request.grant @hugh

    assert request.granted?
    assert_equal @hugh, request.donor
    assert !request.flagged?
    assert !request.sent?

    request.save!
    event.save!
    verify_event request.donation, "grant", user: @hugh
  end

  test "grant no address" do
    request = @howard_request
    event = request.grant @hugh

    assert @howard_request.granted?
    assert_equal @hugh, request.donor
    assert request.flagged?
    assert !request.sent?

    request.save!
    event.save!
    verify_event request.donation, "grant", user: @hugh
  end

  test "grant is idempotent" do
    request = @quentin_request
    event = request.grant @hugh
    assert Event.exists?(event)

    request.save!
    assert request.granted?
    assert_equal 1, request.donations.size
    assert_equal @quentin_donation, request.donation
    assert_equal 1, request.donation.grant_events.size
  end

  test "can't grant if already granted" do
    request = @quentin_request
    event = request.grant @cameron
    assert request.invalid?
  end

  test "can't grant to self" do
    request = @quentin_request_open
    event = request.grant @quentin
    assert request.invalid?
  end

  # Build update event

  test "build update event" do
    @howard_request.address = "123 Independence St"
    event = @howard_request.build_update_event
    assert_equal "update", event.type
    assert_equal @howard, event.user
    assert_equal "added a shipping address", event.detail
    assert event.message.blank?, event.message.inspect
  end

  test "update requires address if granted" do
    @quentin_request.address = ""
    @quentin_request.valid?
    assert @quentin_request.errors[:address].any?, @quentin_request.errors.inspect
  end

  # Cancel

  test "cancel" do
    event = @hank_request.cancel event: {message: "Don't want it anymore"}
    assert @hank_request.canceled?
    assert @hank_request.donation.canceled?

    assert_equal "cancel_request", event.type
    assert_equal @hank_request, event.request
    assert_equal @hank, event.user
    assert_equal @hank_donation, event.donation
    assert_equal "Don't want it anymore", event.message
    assert_equal @cameron, event.to
  end

  test "cancel no donor" do
    event = @howard_request.cancel event: {message: "I bought the book myself"}
    assert @howard_request.canceled?

    assert_equal "cancel_request", event.type
    assert_equal @howard_request, event.request
    assert_equal @howard, event.user
    assert_equal "I bought the book myself", event.message
    assert_nil event.donation
    assert_nil event.to
  end
end
