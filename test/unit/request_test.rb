require 'test_helper'

class RequestTest < ActiveSupport::TestCase
  def reason
    "I've heard so much about this... can't wait to find out who is John Galt!"
  end

  # Creating

  test "build" do
    request = @howard.requests.build book: @atlas, other_book: "", reason: reason, pledge: "1"
    assert request.valid?, request.errors.inspect
    assert_equal @atlas, request.book
  end

  test "other book" do
    request = @howard.requests.build book: nil, other_book: "Ulysses", reason: reason, pledge: "1"
    assert request.valid?, request.errors.inspect
    assert_equal "Ulysses", request.book.title
  end

  test "reason is required" do
    request = @howard.requests.build book: @atlas, other_book: "", reason: "", pledge: "1"
    assert request.invalid?
  end

  test "pledge is required" do
    request = @howard.requests.build book: @atlas, other_book: "", reason: reason
    assert request.invalid?
  end

  test "create" do
    request = @howard.requests.create! book: @atlas, other_book: "", reason: reason, pledge: "1"
    assert_open_at_is_recent request
  end

  # Associations

  test "user" do
    assert_equal @howard, @howard_request.user
  end

  test "book" do
    assert_equal @atlas, @howard_request.book
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

  test "with prices" do
    verify_scope(:with_prices) {|request| request.book.price && request.book.price > 0}
  end

  test "renewable" do
    verify_scope(:renewable) {|request| request.active? && request.can_renew?}
  end

  test "autocancelable" do
    verify_scope(:autocancelable) {|request| request.active? && request.can_autocancel?}
  end

  # Pseudo-scopes

  test "for send-books mode" do
    requests = Request.for_mode(ActiveSupport::StringInquirer.new("send_books"))
    assert requests.any?, "no requests for send-books mode"
    requests.each do |request|
      assert request.active?, "request #{request.id} is not active"
      assert request.open?, "request #{request.id} is not open"
    end
  end

  test "for send-money mode" do
    requests = Request.for_mode(ActiveSupport::StringInquirer.new("send_money"))
    assert requests.any?, "no requests for send-money mode"
    requests.each do |request|
      assert request.active?, "request #{request.id} is not active"
      assert request.open?, "request #{request.id} is not open"
      assert request.book.price, "request #{request.id} has no price for #{request.book}"
      assert request.book.price > 0, "request #{request.id} has price of zero for #{request.book}"

      assert_not_nil request.user.location
      assert_equal "United States", request.user.location.country
    end
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

  test "needs fix?" do
    assert @dagny_request.needs_fix?, "dagny request doesn't need fix"
    assert !@howard_request.needs_fix?, "howard request needs fix"
    assert !@quentin_request.needs_fix?, "quentin request needs fix"
    assert !@dagny_request_canceled.needs_fix?, "dagny request canceled needs fix"
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

  # Can renew?

  test "can renew? true if old" do
    request = build :request, open_at: 5.weeks.ago
    assert request.can_renew?
  end

  test "can renew? true even if canceled" do
    request = build :request, open_at: 5.weeks.ago, canceled: true
    assert request.can_renew?
  end

  test "can renew? false if recent" do
    request = build :request
    assert !request.can_renew?
  end

  test "can renew? false if granted" do
    request = create :request, open_at: 5.weeks.ago
    donation = create :donation, request: request
    assert !request.can_renew?
  end

  # Can uncancel?

  test "can uncancel? true if canceled" do
    request = build :request, canceled: true
    assert request.can_uncancel?
  end

  test "can uncancel? false if active" do
    request = build :request
    assert !request.can_uncancel?
  end

  test "can uncancel? false unless user.can_request?" do
    request = create :request, canceled: true
    request2 = create :request, user: request.user
    assert !request.can_uncancel?
  end

  # Can autocancel?

  test "can autocancel? true if open and old" do
    request = build :request, created_at: 9.weeks.ago, open_at: 9.weeks.ago
    assert request.can_autocancel?
  end

  test "can autocancel? false if recent" do
    request = build :request, created_at: 9.weeks.ago, open_at: Time.now
    assert !request.can_autocancel?
  end

  test "can autocancel? false if granted" do
    request = create :request, created_at: 9.weeks.ago, open_at: 9.weeks.ago
    request.grant!
    assert !request.can_autocancel?
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
  end

  test "cancel no donor" do
    event = @howard_request.cancel event: {message: "I bought the book myself"}
    assert @howard_request.canceled?

    assert_equal "cancel_request", event.type
    assert_equal @howard_request, event.request
    assert_equal @howard, event.user
    assert_equal "I bought the book myself", event.message
    assert_nil event.donation
  end

  test "cancel when already canceled" do
    event = @howard_request_canceled.cancel
    assert @howard_request_canceled.canceled?
    assert_nil event
  end

  test "cancel raises exception if you can't cancel" do
    assert_raise RuntimeError do
      @quentin_request.cancel
    end
  end

  # Renew

  test "renew" do
    request = create :request, open_at: 5.weeks.ago
    attributes = {user_name: "John Galt", address: "123 Rationality Way"}
    event = request.renew attributes

    assert_open_at_is_recent request
    assert_equal "John Galt", request.user.name
    assert_equal "123 Rationality Way", request.user.address
    assert_equal "renew", event.type
    assert_equal "renewed", event.detail
  end

  test "renew for canceled request" do
    request = create :request, open_at: 60.days.ago, canceled: true
    attributes = {user_name: "John Galt", address: "123 Rationality Way"}
    event = request.renew attributes

    assert request.active?
    assert_open_at_is_recent request
    assert_equal "John Galt", request.user.name
    assert_equal "123 Rationality Way", request.user.address
    assert_equal "renew", event.type
    assert_equal "reopened", event.detail
  end

  test "renew for a recently-canceled request" do
    open_at = 1.day.ago
    request = create :request, open_at: open_at, canceled: true
    event = request.renew

    assert request.active?
    assert_equal open_at, request.open_at
    assert_equal "renew", event.type
    assert_equal "uncanceled", event.detail
  end

  test "renew for a recently opened request is a no-op" do
    open_at = 1.day.ago
    request = create :request, open_at: open_at
    event = request.renew

    assert request.active?
    assert_equal open_at, request.open_at
    assert_nil event
  end
end
