require 'test_helper'

class EventTest < ActiveSupport::TestCase
  def setup
    super
    @new_flag = @dagny_donation.flag_events.build message: "Problem here"
    @new_fix = @hank_donation.fix_events.build detail: "updated shipping info", message: "Fixed"
    @new_message = @hank_donation.message_events.build user: @hank, message: "Info is correct"
    @new_thank = @quentin_donation.message_events.build user: @quentin, message: "Thanks!", is_thanks: true, public: false
    @new_cancel = @hank_donation.cancel_donation_events.build user: @cameron, message: "Sorry!"
    @new_student_cancel = @quentin_donation_unsent.cancel_donation_events.build user: @quentin, detail: "not_received"
  end

  # Associations

  test "request" do
    assert_equal @quentin_request, events(:hugh_grants_quentin).request
  end

  test "user" do
    assert_equal @hugh, events(:hugh_grants_quentin).user
    assert_equal @quentin, events(:quentin_adds_name).user
  end

  test "donor" do
    assert_equal @hugh, events(:hugh_grants_quentin).donor
  end

  test "donation" do
    assert_equal @quentin_donation, events(:hugh_grants_quentin).donation
  end

  # Scopes

  test "public thanks" do
    verify_scope(Event, :public_thanks) {|event| event.is_thanks? && event.public?}
  end

  # Validations

  test "valid flag" do
    assert @new_flag.valid?, @new_flag.errors.inspect
  end

  test "flag requires message" do
    @new_flag.message = ""
    assert @new_flag.invalid?
    assert @new_flag.errors[:message].any?
  end

  test "valid fix" do
    assert @new_fix.valid?, @new_fix.errors.inspect
  end

  test "flag with detail doesn't need message" do
    @new_fix.message = ""
    assert @new_fix.valid?, @new_fix.errors.inspect
  end

  test "flag with message doesn't need detail" do
    @new_fix.detail = nil
    assert @new_fix.valid?, @new_fix.errors.inspect
  end

  test "flag requires detail or message" do
    @new_fix.detail = nil
    @new_fix.message = ""
    assert @new_fix.invalid?
    assert @new_fix.errors[:message].any?
  end

  test "valid message" do
    assert @new_message.valid?, @new_message.errors.inspect
  end

  test "message requires message" do
    @new_message.message = ""
    assert @new_message.invalid?
    assert @new_message.errors[:message].any?
  end

  test "valid thank" do
    assert @new_thank.valid?, @new_thank.errors.inspect
  end

  test "thank requires explicit public bit" do
    @new_thank.public = nil
    assert @new_thank.invalid?
    assert @new_thank.errors[:public].any?
  end

  test "valid cancel" do
    assert @new_cancel.valid?, @new_cancel.errors.inspect
  end

  test "cancel requires message" do
    @new_cancel.message = ""
    assert @new_cancel.invalid?
    assert @new_cancel.errors[:message].any?
  end

  test "valid student cancel" do
    assert @new_student_cancel.valid?, @new_student_cancel.errors.inspect
  end

  test "validates type" do
    @new_flag.type = "random"
    assert @new_flag.invalid?
  end

  # Derived attributes

  test "book" do
    assert_equal @atlas, events(:cameron_grants_hank).book
  end

  test "student" do
    assert_equal @quentin, events(:hugh_grants_quentin).student
    assert_equal @quentin, events(:quentin_adds_name).student
  end

  # Recipients

  test "recipients empty for update before grant" do
    request = create :request
    request.address = "123 New Address St"
    event = request.build_update_event
    assert_equal [], event.recipients
  end

  test "recipients for message" do
    donation = create :donation
    event = donation.message! donation.user
    assert_equal [donation.student], event.recipients
  end

  test "recipients for broaadcast message" do
    fulfillment = create :fulfillment
    event = fulfillment.donation.message! fulfillment.student
    assert_equal [fulfillment.donor, fulfillment.user], event.recipients
  end

  test "recipients for private message" do
    fulfillment = create :fulfillment
    event = fulfillment.donation.message! fulfillment.user, recipient: fulfillment.student
    assert_equal [fulfillment.student], event.recipients
  end

  test "recipients for reply to thank-you" do
    fulfillment = create :fulfillment
    orig = fulfillment.donation.thank!
    event = fulfillment.donation.message! fulfillment.user, reply_to_event: orig
    assert_equal [fulfillment.student], event.recipients
  end

  test "recipients for reply to broadcast message" do
    fulfillment = create :fulfillment
    orig = fulfillment.donation.message! fulfillment.student
    event = fulfillment.donation.message! fulfillment.user, reply_to_event: orig
    assert_equal [fulfillment.student, fulfillment.donor], event.recipients
  end

  test "recipients for private reply to broadcast message" do
    fulfillment = create :fulfillment
    orig = fulfillment.donation.message! fulfillment.student
    event = fulfillment.donation.message! fulfillment.user, reply_to_event: orig, recipient: fulfillment.student
    assert_equal [fulfillment.student], event.recipients
  end

  test "recipients for reply to status update" do
    fulfillment = create :fulfillment
    orig = fulfillment.donation.update_status! "read"
    event = fulfillment.donation.message! fulfillment.user, reply_to_event: orig
    assert_equal [fulfillment.student], event.recipients
  end

  test "recipients for flag and fix" do
    fulfillment = create :fulfillment
    event = fulfillment.donation.flag!
    assert_equal [fulfillment.student, fulfillment.donor], event.recipients

    event = fulfillment.donation.fix!
    assert_equal [fulfillment.user], event.recipients
  end

  # Actions

  test "notify" do
    event = events :hugh_messages_quentin
    assert !event.notified?
    assert_difference("ActionMailer::Base.deliveries.count") { event.notify }
    assert event.notified?
  end

  test "notify to multiple recipients" do
    @frisco_donation.fulfill @kira
    event = @frisco_donation.flag user: @kira, message: "Fix this"
    @frisco_donation.save!

    assert !event.notified?
    assert_difference("ActionMailer::Base.deliveries.count", 2) { event.notify }
    assert event.notified?
  end

  test "notify for private message" do
    fulfillment = create :fulfillment

    assert_difference("ActionMailer::Base.deliveries.count", 1) do
      event = fulfillment.donation.message! fulfillment.user, recipient: fulfillment.student
      assert event.notified?
    end
  end

  test "notify on fix only goes to fulfiller" do
    fulfillment = create :fulfillment
    fulfillment.donation.flag!

    assert_difference("ActionMailer::Base.deliveries.count", 1) do
      event = fulfillment.donation.fix!
      assert event.notified?
    end
  end

  test "notify is idempotent" do
    event = events :quentin_adds_name
    assert event.notified?
    assert_no_difference("ActionMailer::Base.deliveries.count") { event.notify }
  end

  test "notify is noop if no recipient" do
    event = events :howard_updates_info
    assert !event.notified?
    assert_no_difference("ActionMailer::Base.deliveries.count") { event.notify }
  end

  # Conversions

  test "to testimonial" do
    event = events :quentin_thanks_hugh
    testimonial = event.to_testimonial
    assert_equal event, testimonial.source
    assert_equal 'student', testimonial.type
    assert_equal "A thank-you", testimonial.title
    assert_equal event.message, testimonial.text
    assert_equal "Quentin Daniels, studying physics at MIT, to donor Hugh Akston", testimonial.attribution
  end
end
