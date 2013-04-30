require 'rexml/document'

class PriceChecker
  def fetch_price(asin)
    config = Rails.application.config
    request = Vacuum.new
    request.configure key: config.aws_access_key, secret: config.aws_secret_key, tag: config.amazon_associates_tag

    Rails.logger.info "Fetching price for #{asin}"
    response = request.get query: {'Operation' => 'ItemLookup', 'ItemId' => asin, 'ResponseGroup' => 'Offers'}
    xml = response.body

    Rails.logger.info "Got XML (#{xml.length} bytes), parsing"
    doc = REXML::Document.new xml
    price = REXML::XPath.first(doc, '//Offer//Price/Amount')
    Money.new price.text.to_i if price
  end

  def adjust_price(price)
    # Heuristic adjustment to cover Amazon payment fees and occasional sales tax
    cents = price.cents
    cents += 75
    rounded_up = ((cents + 99) / 100) * 100
    Money.new rounded_up
  end

  def update_price!(book)
    if book.asin.blank?
      Rails.logger.info "Book #{book} has no ASIN"
      return
    end

    price = fetch_price book.asin
    if price.blank?
      Rails.logger.info "Couldn't find price for #{book} #{book.asin}"
      return
    end
    Rails.logger.info "Latest price for #{book}: #{price.format}"

    adjusted = adjust_price price
    Rails.logger.info "Adjusted price for #{book}: #{adjusted.format}"

    book.price = adjusted
    book.save!
  end

  def update_all_prices(books)
    books.find_each do |book|
      update_price! book
    end
  end

  def perform
    update_all_prices Book.with_asin
  end

  def self.schedule
    Delayed::Job.enqueue new
  end
end
