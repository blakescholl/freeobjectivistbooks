require 'test_helper'

class PledgeHelperTest < ActionView::TestCase
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
end
