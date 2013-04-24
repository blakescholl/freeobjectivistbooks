require 'test_helper'

class PledgeHelperTest < ActionView::TestCase
  # Feedback for non-recurring pledges

  test "feedback for new pledge" do
    pledge = create :pledge
    assert_equal "You haven't donated any books towards this pledge yet.", feedback_for(pledge)
  end

  test "feedback for empty pledge" do
    pledge = create :pledge, :ended
    assert_equal "You didn't get a chance to donate any books towards this pledge, oh well.", feedback_for(pledge)
  end

  test "feedback for pledge with 1 donation" do
    pledge = create :pledge
    create :donation, user: pledge.user
    assert_match /You have donated 1 book towards this pledge so far, [\w\s]+!/, feedback_for(pledge)
  end

  test "feedback for ended pledge with 1 donation" do
    pledge = create :pledge
    create :donation, user: pledge.user
    pledge.ended = true
    assert_match /You donated 1 book towards this pledge, [\w\s]+[\.!]/, feedback_for(pledge)
  end

  test "feedback for pledge with multiple donations" do
    pledge = create :pledge
    create_list :donation, 2, user: pledge.user
    assert_match /You have donated 2 books towards this pledge so far, [\w\s]+!/, feedback_for(pledge)
  end

  test "feedback for ended pledge with multiple donations" do
    pledge = create :pledge
    create_list :donation, 2, user: pledge.user
    pledge.ended = true
    assert_match /You donated 2 books towards this pledge, [\w\s]+[\.!]/, feedback_for(pledge)
  end

  test "feedback for fulfilled pledge" do
    pledge = create :pledge, quantity: 1
    create_list :donation, 1, user: pledge.user
    assert_match /You have fulfilled this pledge, [\w\s]+!/, feedback_for(pledge)
  end

  test "feedback for ended fulfilled pledge" do
    pledge = create :pledge, quantity: 1
    create_list :donation, 1, user: pledge.user
    pledge.ended = true
    assert_match /You fulfilled this pledge, [\w\s]+!/, feedback_for(pledge)
  end

  test "feedback for exceeded pledge" do
    pledge = create :pledge, quantity: 1
    create_list :donation, 2, user: pledge.user
    assert_match /You have exceeded this pledge with 2 books, [\w\s]+!/, feedback_for(pledge)
  end

  test "feedback for ended exceeded pledge" do
    pledge = create :pledge, quantity: 1
    create_list :donation, 2, user: pledge.user
    pledge.ended = true
    assert_match /You exceeded this pledge with 2 books, [\w\s]+!/, feedback_for(pledge)
  end

  # Feedback for recurring pledges

  test "feedback for new recurring pledge" do
    pledge = create :pledge, :recurring
    assert_equal "You haven't donated any books this month yet.", feedback_for(pledge)
  end

  test "feedback for empty recurring pledge" do
    pledge = create :pledge, :recurring, :ended
    assert_equal "You didn't get a chance to donate any books this month, oh well.", feedback_for(pledge)
  end

  test "feedback for recurring pledge with 1 donation" do
    pledge = create :pledge, :recurring
    create :donation, user: pledge.user
    assert_match /You have donated 1 book this month so far, [\w\s]+!/, feedback_for(pledge)
  end

  test "feedback for ended recurring pledge with 1 donation" do
    pledge = create :pledge, :recurring
    create :donation, user: pledge.user
    pledge.ended = true
    assert_match /You donated 1 book this month, [\w\s]+[\.!]/, feedback_for(pledge)
  end

  test "feedback for recurring pledge with multiple donations" do
    pledge = create :pledge, :recurring
    create_list :donation, 2, user: pledge.user
    assert_match /You have donated 2 books this month so far, [\w\s]+!/, feedback_for(pledge)
  end

  test "feedback for ended recurring pledge with multiple donations" do
    pledge = create :pledge, :recurring
    create_list :donation, 2, user: pledge.user
    pledge.ended = true
    assert_match /You donated 2 books this month, [\w\s]+[\.!]/, feedback_for(pledge)
  end

  test "feedback for fulfilled recurring pledge" do
    pledge = create :pledge, :recurring, quantity: 1
    create_list :donation, 1, user: pledge.user
    assert_match /You have fulfilled your pledge this month, [\w\s]+!/, feedback_for(pledge)
  end

  test "feedback for ended fulfilled recurring pledge" do
    pledge = create :pledge, :recurring, quantity: 1
    create_list :donation, 1, user: pledge.user
    pledge.ended = true
    assert_match /You fulfilled your pledge this month, [\w\s]+!/, feedback_for(pledge)
  end

  test "feedback for exceeded recurring pledge" do
    pledge = create :pledge, :recurring, quantity: 1
    create_list :donation, 2, user: pledge.user
    assert_match /You have exceeded your pledge this month with 2 books, [\w\s]+!/, feedback_for(pledge)
  end

  test "feedback for ended exceeded recurring pledge" do
    pledge = create :pledge, :recurring, quantity: 1
    create_list :donation, 2, user: pledge.user
    pledge.ended = true
    assert_match /You exceeded your pledge this month with 2 books, [\w\s]+!/, feedback_for(pledge)
  end

  # Pledge summary

  test "pledge summary" do
    pledge = build :pledge
    assert_equal "pledged to donate 5 books", pledge_summary(pledge)
  end

  test "pledge summary for quantity = 1" do
    pledge = build :pledge, quantity: 1
    assert_equal "pledged to donate 1 book", pledge_summary(pledge)
  end

  test "pledge summary for recurring pledge" do
    pledge = build :pledge, :recurring
    assert_equal "pledged to donate 5 books per month", pledge_summary(pledge)
  end

  test "pledge summary for recurring pledge with quantity = 1" do
    pledge = build :pledge, :recurring, quantity: 1
    assert_equal "pledged to donate 1 book per month", pledge_summary(pledge)
  end
end
