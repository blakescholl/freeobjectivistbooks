class Metrics::FulfillmentsTable
  attr_reader :columns, :rows

  def initialize(options = {})
    @group = options[:group]
    @since = options[:since]
    populate
  end

  def populate
    query = Fulfillment.group(:user_id)
    query = query.group(@group) if @group
    query = query.where('fulfillments.created_at >= ?', @since) if @since
    @counts = query.count

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

    sorted_col_ids = col_ids.sort.reverse
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
