module ApplicationHelper
  # User agent

  def touch_device?
    request.user_agent =~ /iPad|iPod|iPhone|Android/
  end

  def chrome?
    request.user_agent =~ /Chrome\/\d+/
  end

  # Generic formatting

  def format_block(text)
    raw (h text).gsub("\n", "<br>")
  end

  def format_address(address)
    address.present? ? format_block(address) : "No address given"
  end

  def count_digits(number)
    if number == 0
      1
    elsif number < 0
      count_digits -number
    else
      1 + Math.log10(number).floor
    end
  end

  def format_number(number, precision = 2)
    return "" if number.nil?
    digits = count_digits number
    precision = digits if precision < digits
    number_with_precision number, precision: precision, significant: true, strip_insignificant_zeros: true, delimiter: ","
  end

  def pluralize_omit_number(count, noun)
    count == 1 ? noun : noun.pluralize
  end

  def pluralize_omit_1(count, noun)
    count == 1 ? noun : "#{count} #{noun.pluralize}"
  end

  def short_date_with_time_ago(date)
    short_date = I18n.l date.to_date, format: :short
    time_ago = distance_of_time_in_words_to_now date
    "#{short_date} (#{time_ago} ago)"
  end

  def title(book)
    raw "<span class=\"title\">#{h book}</span>"
  end

  # Markdown

  def markdown_renderer
    @@renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  end

  def markdown(text)
    raw markdown_renderer.render(text)
  end

  # Model-specific formatting

  def user_tagline(user)
    parts = []
    parts << "studying #{user.studying}" unless user.studying.blank?
    parts << "at #{user.school}" unless user.school.blank?
    parts << "in #{user.location}" unless user.location.nil?
    tagline = parts.join " "
    tagline[0] = tagline[0].upcase
    tagline
  end

  def status_headline(request)
    if request.canceled?
      "Canceled"
    elsif request.read?
      "Finished reading"
    elsif request.received?
      "Book received"
    elsif request.sent?
      "Book sent"
    elsif request.granted?
      "Donor found"
    else
      "Looking for donor"
    end
  end

  def status_detail(request)
    if request.canceled?
      "This request has been canceled."
    elsif request.read?
      "#{request.user} has read this book."
    elsif request.received?
      "#{request.user} has received this book."
    elsif request.sent?
      "#{request.sender} has sent this book."
    elsif request.granted?
      "#{request.donor} in #{request.donor.location} will donate this book."
    else
      "We are looking for a donor for this book."
    end
  end

  def request_summary(request)
    student = request.student
    name = h student.name
    book = title request.book
    raw "#{name} wants to read #{book}"
  end

  def donation_summary(donation)
    donor = donation.donor
    name = h donor.name
    location = h donor.location
    book = title donation.book
    raw "#{name} in #{location} donated #{book} to you"
  end

  def role_description(role)
    case role
    when :donor then "the donor"
    when :fulfiller then "Free Objectivist Books volunteer"
    end
  end

  # Pagination

  def has_more?
    @total.present? && @end.present? && @total > @end
  end

  def more_link
    if has_more?
      params = {offset: @end, limit: params[:limit]}
      path = yield params
      link_to 'More', path
    end
  end
end
