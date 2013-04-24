require 'test_helper'

class PledgeTest < ActiveSupport::TestCase
  def reason
    "I want to spread these great ideas."
  end

  # Associations

  test "user" do
    assert_equal @hugh, @hugh_pledge.user
  end

  test "referral" do
    assert_equal @fb_referral, @stadler_pledge.referral
    assert_nil @hugh_pledge.referral
  end

  test "reminders" do
    assert_equal [@hugh_reminder], @hugh_pledge.reminders
    assert_equal [], @cameron_pledge.reminders
  end

  # Validations

  test "build" do
    pledge = @hugh.pledges.build quantity: "5", reason: reason
    assert pledge.valid?
  end

  test "quantity is required" do
    pledge = @hugh.pledges.build quantity: "", reason: reason
    assert pledge.invalid?
  end

  test "quantity must be a number" do
    pledge = @hugh.pledges.build quantity: "x", reason: reason
    assert pledge.invalid?
  end

  test "quantity must be positive" do
    pledge = @hugh.pledges.build quantity: "0", reason: reason
    assert pledge.invalid?
  end

  # Update event

  test "build update event" do
    pledge = create :pledge
    pledge.quantity = 10
    event = pledge.build_update_event

    assert_not_nil event
    assert_equal pledge, event.pledge
    assert_equal pledge.user, event.user
    assert_equal "update", event.type
  end

  # End if needed

  test "end if needed" do
    pledge = create :pledge, :endable
    user = pledge.user

    assert_difference "ActionMailer::Base.deliveries.count" do
      new_pledge = pledge.end_if_needed!
      assert pledge.ended?, "pledge is not ended"
      assert_nil new_pledge, "got new pledge"
    end

    user.reload
    assert_nil user.current_pledge, "user has current pledge"
    assert_equal pledge, user.latest_pledge
  end

  test "end if needed for recurring pledge" do
    pledge = create :pledge, :recurring, :endable
    user = pledge.user

    new_pledge = nil
    assert_difference "ActionMailer::Base.deliveries.count" do
      new_pledge = pledge.end_if_needed!
      assert pledge.ended?, "pledge is not ended"
    end

    user.reload

    assert_equal user, new_pledge.user
    assert_equal pledge.quantity, new_pledge.quantity
    assert new_pledge.active?, "new pledge is not active"
    assert new_pledge.recurring?, "new pledge is not recurring"
    assert_equal 0, new_pledge.donations_count

    assert_equal new_pledge, user.current_pledge
    assert_equal new_pledge, user.latest_pledge
  end

  test "end if needed is idempotent" do
    pledge = create :pledge, :ended, :endable

    assert_no_difference "ActionMailer::Base.deliveries.count" do
      pledge.end_if_needed!
      assert pledge.ended?
    end
  end

  test "end if needed does nothing if pledge canceled" do
    pledge = create :pledge, :canceled, :endable

    assert_no_difference "ActionMailer::Base.deliveries.count" do
      pledge.end_if_needed!
      assert !pledge.ended?
    end
  end

  test "end if needed doesn't end new pledges" do
    pledge = create :pledge

    assert_no_difference "ActionMailer::Base.deliveries.count" do
      pledge.end_if_needed!
      assert !pledge.ended?
    end
  end

  # Derived attributes

  test "fulfilled?" do
    pledge = create :pledge, quantity: 1
    assert !pledge.fulfilled?, "pledge is fulfilled"

    create :donation, user: pledge.user
    assert pledge.fulfilled?, "pledge not fulfilled"

    pledge.cancel!
    assert pledge.fulfilled?, "pledge not fulfilled after cancel"

    new_pledge = create :pledge, quantity: 1
    assert !new_pledge.fulfilled?, "new pledge is fulfilled"
  end

  test "fulfilled" do
    verify_scope(Pledge, :unfulfilled) {|pledge| !pledge.fulfilled?}
  end

  test "to testimonial" do
    testimonial = @hugh_pledge.to_testimonial
    assert_equal @hugh_pledge, testimonial.source
    assert_equal 'donor', testimonial.type
    assert_equal "From a donor", testimonial.title
    assert_equal @hugh_pledge.reason, testimonial.text
    assert_equal "Hugh Akston, Boston, MA", testimonial.attribution
  end
end
