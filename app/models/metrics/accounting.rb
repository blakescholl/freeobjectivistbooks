class Metrics::Accounting
  def number(value)
    value || 0
  end

  def money(value)
    value ? Money.new(value) : Money.new(0)
  end

  def table
    columns = [
      'Contributors',
      'Contributions',
      'Contribution $',
      'Paying donors',
      'Paid donations sent',
      'Paid donation $',
    ]

    contribution_group = Contribution.group('extract(year from created_at)', 'extract(month from created_at)')
    contribution_users = contribution_group.count('distinct user_id')
    contribution_count = contribution_group.count
    contribution_total = contribution_group.sum(:amount_cents)

    donations = Donation.unscoped.active.paid.sent
    donation_group = donations.group('extract(year from created_at)', 'extract(month from created_at)')
    donation_users = donation_group.count('distinct user_id')
    donation_count = donation_group.count
    donation_total = donation_group.sum(:price_cents)

    keys = contribution_count.keys

    rows = keys.map do |key|
      year, month = key
      date = Date.new year.to_i, month.to_i
      {
        date: date,
        name: date.strftime("%B %Y"),
        values: {
          'Contributors' => number(contribution_users[key]),
          'Contributions' => number(contribution_count[key]),
          'Contribution $' => money(contribution_total[key]).format,
          'Paying donors' => number(donation_users[key]),
          'Paid donations sent' => number(donation_count[key]),
          'Paid donation $' => money(donation_total[key]).format,
        },
      }
    end
    rows.sort_by! {|r| r[:date]}

    Metrics::Table.new columns, rows
  end
end
