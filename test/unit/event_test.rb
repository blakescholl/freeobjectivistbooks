require 'test_helper'

class EventTest < ActiveSupport::TestCase
  def setup
    @quentin = users :quentin
    @hugh = users :hugh
    @quentin_wants_vos = requests :quentin_wants_vos
  end

  # Associations

  test "request" do
    assert_equal @quentin_wants_vos, events(:hugh_granted_quentin).request
  end

  test "user" do
    assert_equal @hugh, events(:hugh_granted_quentin).user
    assert_equal @quentin, events(:quentin_added_name).user
  end

  test "donor" do
    assert_equal @hugh, events(:hugh_granted_quentin).donor
  end

  # Validations

  test "validates type" do
    assert Event.new(type: "random").invalid?
  end

  # Derived attributes

  test "to" do
    assert_equal @quentin, events(:hugh_granted_quentin).to
    assert_equal @hugh, events(:quentin_added_name).to
  end

  test "to student?" do
    assert events(:hugh_granted_quentin).to_student?
    assert !events(:quentin_added_name).to_student?
  end

  test "to donor?" do
    assert !events(:hugh_granted_quentin).to_donor?
    assert events(:quentin_added_name).to_donor?
  end
end
