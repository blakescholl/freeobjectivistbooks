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

  test "merge with duplicate" do
    book1 = create :book
    book2 = create :book, title: "Atlas Shruged"
    request1 = create :request, book: book1
    request2 = create :request, book: book2
    review1 = create :review, book: book1
    review2 = create :review, book: book2

    book1.merge_with_duplicate book2

    assert_equal book1, request1.reload.book
    assert_equal book1, request2.reload.book
    assert_equal book1, review1.reload.book
    assert_equal book1, review2.reload.book
  end
end
