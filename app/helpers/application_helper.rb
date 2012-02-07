module ApplicationHelper
  def touch_device?
    request.user_agent =~ /iPad|iPod|iPhone|Android/
  end

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
      digits -number
    else
      1 + Math.log10(number).floor
    end
  end

  def format_number(number, precision = 2)
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

  def user_tagline(user)
    parts = []
    parts << "studying #{user.studying}" unless user.studying.blank?
    parts << "at #{user.school}" unless user.school.blank?
    parts << "in #{user.location}" unless user.location.blank?
    tagline = parts.join " "
    tagline[0] = tagline[0].upcase
    tagline
  end

  def status_headline(request)
    if request.received?
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
    if request.received?
      "#{request.user.name} has received this book."
    elsif request.sent?
      "#{request.donor.name} in #{request.donor.location} has sent this book."
    elsif request.granted?
      "#{request.donor.name} in #{request.donor.location} will donate this book."
    else
      "We are looking for a donor for this book."
    end
  end
end
