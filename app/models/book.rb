# Represents a book that students can request.
class Book < ActiveRecord::Base
  monetize :price_cents, allow_nil: true

  scope :featured, where(featured: true).order(:rank)

  # The default book for new requests.
  def self.default_book
    find_or_create_by_title "Atlas Shrugged"
  end

  def amazon_url
    "http://www.amazon.com/dp/#{asin}/" if asin
  end

  def to_s
    title
  end
end
