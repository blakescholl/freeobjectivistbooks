class Metrics::FulfillmentsTable
  attr_reader :columns, :rows

  def initialize(options = {})
    @group = options[:group]
    @since = options[:since]
    populate
  end

  def fulfillments_query
    query = Fulfillment.group(:user_id)

    query = case @group
      when :day then query.group('date(created_at)')
      when :week then query.group("date(date_trunc('week', created_at))")
    end

    query.where('fulfillments.created_at >= ?', @since)
  end

  def populate
    @counts = fulfillments_query.count

    col_ids = Set.new
    row_ids = Set.new
    @col_totals = Hash.new(0)
    @row_totals = Hash.new(0)
    @total = 0

    @counts.each do |key,count|
      row, col = key
      col_ids << col
      row_ids << row
      @col_totals[col] += count
      @row_totals[row] += count
      @total += count
    end

    if col_ids.any?
      start_date = Date.parse col_ids.min
      end_date = Date.parse col_ids.max
      range = (start_date .. end_date)
      range = range.step(7) if @group == :week
      sorted_col_ids = range.map {|date| date.to_s}.reverse
    else
      sorted_col_ids = []
    end

    sorted_row_ids = row_ids.sort_by {|row| -@row_totals[row]}

    @columns = sorted_col_ids + [:total]
    @rows = sorted_row_ids.map {|id| User.find id} + [:total]
  end

  def column_name(column)
    if column == :total
      "Total"
    else
      date = Date.parse column
      I18n.l date, format: :short
    end
  end

  def row_name(row)
    if row == :total
      "Total"
    else
      row.to_s
    end
  end

  def has_link?(row)
    row != :total
  end

  def row_target(row)
    [:admin, row]
  end

  def value(row, column)
    if row == :total && column == :total
      @total
    elsif row == :total
      @col_totals[column]
    elsif column == :total
      @row_totals[row.id]
    else
      key = [row.id, column]
      @counts[key]
    end
  end
end
