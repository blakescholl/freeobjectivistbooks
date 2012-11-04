require 'test_helper'

class ReviewTest < ActiveSupport::TestCase
  # Associations

  test "user" do
    assert_equal @quentin, @quentin_review.user
  end

  test "donation" do
    assert_equal @quentin_donation_read, @quentin_review.donation
  end

  # Validations

  test "valid reviews" do
    assert @quentin_review.valid?
    assert @stadler_review.valid?
  end

  test "validates user" do
    @quentin_review.user = nil
    assert @quentin_review.invalid?
    assert @quentin_review.errors[:user].any?
  end

  test "validates book" do
    @quentin_review.book_id = nil
    assert @quentin_review.invalid?
    assert @quentin_review.errors[:book].any?
  end

  test "validates text" do
    @quentin_review.text = " "
    assert @quentin_review.invalid?
    assert @quentin_review.errors[:text].any?
  end

  test "validates recommend" do
    @quentin_review.recommend = nil
    assert @quentin_review.invalid?
    assert @quentin_review.errors[:recommend].any?
  end

  # To testimonial

  test "to testimonial" do
    testimonial = @quentin_review.to_testimonial
    assert_equal @quentin_review, testimonial.source
    assert_equal 'student', testimonial.type
    assert_equal "On *Atlas Shrugged*", testimonial.title
    assert_equal @quentin_review.text, testimonial.text
    assert_equal "Quentin Daniels, studying physics at MIT", testimonial.attribution
  end
end
