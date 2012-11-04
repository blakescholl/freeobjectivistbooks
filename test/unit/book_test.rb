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
end
