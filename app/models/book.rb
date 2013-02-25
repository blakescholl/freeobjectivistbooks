# Represents a book that students can request.
class Book < ActiveRecord::Base
  monetize :price_cents, allow_nil: true

  scope :featured, where(featured: true).order(:rank)
  scope :with_prices, where('books.price_cents is not null').where('books.price_cents > 0')

  # The default book for new requests.
  def self.default_book
    find_or_create_by_title "Atlas Shrugged"
  end

  def amazon_url
    "http://www.amazon.com/dp/#{asin}/" if asin
  end

  def merge_with_duplicate(other)
    Request.where(book_id: other).update_all(book_id: self)
    Review.where(book_id: other).update_all(book_id: self)
    other.destroy
  end

  #--
  # Conversions
  #++

  def to_s
    title
  end

  def as_json(options = {})
    hash_from_methods :id, :title, :author, :asin, :price_cents
  end
end
