require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  include ERB::Util

  # Generic formatting

  test "format number" do
    assert_equal "0", format_number(0)
    assert_equal "0.5", format_number(0.49876)
    assert_equal "0.5", format_number(0.5)
    assert_equal "0.54", format_number(0.54321)
    assert_equal "1", format_number(1)
    assert_equal "9", format_number(9)
    assert_equal "9.9", format_number(9.949)
    assert_equal "10", format_number(9.95)
    assert_equal "10", format_number(10)
    assert_equal "10", format_number(10.3)
    assert_equal "11", format_number(11)
    assert_equal "99", format_number(99)
    assert_equal "100", format_number(100)
    assert_equal "100", format_number(100.3)
    assert_equal "101", format_number(101)
    assert_equal "999", format_number(999)
    assert_equal "1,000", format_number(1000)
  end

  test "format negative numbers" do
    assert_equal "-0.5", format_number(-0.5)
    assert_equal "-1", format_number(-1)
    assert_equal "-11", format_number(-11)
    assert_equal "-99", format_number(-99)
    assert_equal "-100", format_number(-100)
    assert_equal "-1,000", format_number(-1000)
  end

  test "pluralize omit number" do
    assert_equal "apples", pluralize_omit_number(0, "apple")
    assert_equal "apple", pluralize_omit_number(1, "apple")
    assert_equal "apples", pluralize_omit_number(2, "apple")
  end

  test "pluralize omit 1" do
    assert_equal "0 apples", pluralize_omit_1(0, "apple")
    assert_equal "apple", pluralize_omit_1(1, "apple")
    assert_equal "2 apples", pluralize_omit_1(2, "apple")
  end

  # Model-specific formatting

  test "student tagline" do
    tagline = "Studying architecture at Stanton Institute of Technology in New York, NY"
    assert_equal tagline, user_tagline(users :howard)
  end

  test "donor tagline" do
    assert_equal "In Boston, MA", user_tagline(users :hugh)
  end

  test "status headline" do
    assert_equal "Looking for donor", status_headline(@howard_request)
    assert_equal "Donor found", status_headline(@dagny_request)
    assert_equal "Book sent", status_headline(@quentin_request)
    assert_equal "Book received", status_headline(@hank_request_received)
    assert_equal "Finished reading", status_headline(@quentin_request_read)
  end

  test "status detail" do
    assert_equal "We are looking for a donor for this book.", status_detail(@howard_request)
    assert_equal "Hugh Akston in Boston, MA will donate this book.", status_detail(@dagny_request)
    assert_equal "Hugh Akston has sent this book.", status_detail(@quentin_request)
    assert_equal "Hank Rearden has received this book.", status_detail(@hank_request_received)
    assert_equal "Quentin Daniels has read this book.", status_detail(@quentin_request_read)
  end

  test "request summary" do
    assert_equal 'Howard Roark wants to read <span class="title">Atlas Shrugged</span>',
      request_summary(@howard_request)
  end

  test "donation summary" do
    assert_equal 'Henry Cameron in New York, NY donated <span class="title">Atlas Shrugged</span> to you',
      donation_summary(@hank_request)
  end
end
