class Metrics::Table
  attr_reader :columns, :rows
  attr_accessor :links

  def initialize(columns, rows, links = {})
    @columns = columns
    @rows = rows
    @links = links
  end

  def with_links(links)
    table = dup
    table.links = links
    table
  end

  def column_name(column)
    column
  end

  def row_name(row)
    row[:name]
  end

  def has_link?(row)
    name = row_name row
    @links.include? name
  end

  def row_target(row)
    @links[row_name row]
  end

  def value(row, column)
    row[:values][column]
  end
end
