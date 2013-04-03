require 'test_helper'

class MetricsTest < ActiveSupport::TestCase
  def setup
    @metrics = Metrics.new
  end

  def values_for(metrics)
    metrics.inject({}) do |hash,metric|
      value = metric[:value] || metric[:values]["Total"]
      hash.merge(metric[:name] => value)
    end
  end

  test "request pipeline" do
    metrics = @metrics.request_pipeline
    values = values_for metrics

    assert_equal values['Active'], values['Granted'] + Request.not_granted.count, metrics.inspect
    assert_equal values['Granted'], values['Sent'] + Donation.not_sent.count, metrics.inspect
    assert_equal values['Sent'], values['Received'] + Donation.in_transit.count, metrics.inspect
    assert_equal values['Received'], values['Read'] + Donation.reading.count, metrics.inspect
    assert_equal Request.count, values['Canceled'] + values['Active'], metrics.inspect
  end

  test "donor mode pipelines" do
    books_metrics = @metrics.send_books_pipeline
    money_metrics = @metrics.send_money_pipeline
    books_values = values_for books_metrics
    money_values = values_for money_metrics

    assert_equal Request.granted.count, books_values['Granted'] + money_values['Granted'], "granted total doesn't match"
    assert_equal money_values['Granted'], money_values['Paid'] + Donation.send_money.unpaid.count, "paid + unpaid != granted"
    assert_equal money_values['Paid'], money_values['Fulfilled'] + Donation.needs_fulfillment.count, "fulfilled + unfulfilled != paid"
    assert_equal Donation.sent.count, books_values['Sent'] + money_values['Sent'], "send total doesn't match"
  end

  test "pipeline breakdown" do
    metrics = @metrics.pipeline_breakdown
    values = values_for metrics.rows

    assert_equal Request.active.count, Request.granted.count + values['Open requests'], "granted + open != total: #{values.inspect}"

    donations = Donation.send_books.not_sent
    assert_equal donations.count, values['Needs sending by donor'] + donations.flagged.count, "needs sending by donor + flagged != not sent: #{values.inspect}"

    donations = Donation.send_money.fulfilled.not_sent
    assert_equal donations.count, values['Needs sending by volunteer'] + donations.flagged.count, "needs sending by volunteer + flagged != not sent: #{values.inspect}"

    assert_equal Donation.send_money.count, values['Needs payment'] + Donation.paid.count, "needs payment + paid != payable: #{values.inspect}"
    assert_equal Donation.paid.count, values['Needs fulfillment'] + Donation.fulfilled.count, "needs fulfillment + fulfilled != paid: #{values.inspect}"
    assert_equal Donation.sent.count, values['In transit'] + Donation.received.count, "in transit + received != sent: #{values.inspect}"
  end

  test "donation metrics" do
    metrics = @metrics.donation_metrics
    values = values_for metrics

    assert_equal Donation.active.count, values['Flagged'] + Donation.not_flagged.count, metrics.inspect
    assert_equal Donation.received.count, values['Needs thanks'] + Donation.received.thanked.count, metrics.inspect
    assert_equal values['Total'], Donation.active.count + values['Canceled'], metrics.inspect
    assert_equal Donation.active.count, values['Thanked'] + Donation.not_thanked.count, metrics.inspect
    assert_equal values['Reviewed'], values['Recommended'] + Review.where(recommend: false).count, metrics.inspect
  end

  test "pledge metrics" do
    metrics = @metrics.pledge_metrics
    values = values_for metrics
    assert_equal values['Average pledge size'], values['Books pledged'].to_f / values['Donors pledging'], metrics.inspect
  end

  test "book leaderboard" do
    metrics = @metrics.book_leaderboard
    rows = metrics.rows

    request_sum = rows.inject(0) {|sum,row| sum += row[:values]["Requested"]}
    assert_equal Request.active.count, request_sum

    donation_sum = rows.inject(0) {|sum,row| sum += row[:values]["Donated"]}
    assert_equal Donation.active.count, donation_sum
  end

  test "referral metrics" do
    keys = @metrics.referral_metrics_keys
    assert !keys.empty?, "referral metrics keys are empty"

    sum = keys.inject(0) do |sum, key|
      metrics = @metrics.referral_metrics(key)
      assert_not_nil metrics
      values = values_for metrics
      sum += values['Clicks']
    end

    assert_equal sum, Referral.count
  end
end
