require 'test_helper'

class BookTest < ActiveSupport::TestCase
  test "featured books" do
    verify_scope(Book, :featured) {|book| book.featured?}
  end

  test "featured books are in rank order" do
    featured = Book.featured
    sorted = featured.sort_by {|book| book.rank}
    assert_equal sorted, featured
  end

  test "Amazon URL" do
    assert_equal "http://www.amazon.com/dp/0451191145/", @atlas.amazon_url
    assert_nil @fountainhead.amazon_url
  end
end
