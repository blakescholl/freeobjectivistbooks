require 'test_helper'

class MetricsTest < ActiveSupport::TestCase
  def setup
    @metrics = Metrics.new
  end

  def values_for(metrics)
    metrics.inject({}) do |hash,metric|
      value = metric[:value] || (metric[:values] && metric[:values]["Total"])
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

  test "send money pipeline" do
    metrics = @metrics.send_money_pipeline
    values = values_for metrics

    assert_equal Request.granted.count, values['Paid'] + Donation.unpaid.count, "paid + unpaid != granted"
    assert_equal values['Paid'], values['Fulfilled'] + Donation.needs_fulfillment.count, "fulfilled + unfulfilled != paid"
    assert_equal Donation.fulfilled.count, values['Sent by volunteer'] + Donation.fulfilled.not_sent.count, "sent + not sent != fulfilled"
  end

  test "pipeline breakdown" do
    metrics = @metrics.pipeline_breakdown
    values = values_for metrics.rows

    assert_equal Request.active.count, Request.granted.count + values['Open requests'], "granted + open != total: #{values.inspect}"

    donations = Donation.unpaid.not_sent
    assert_equal donations.count, values['Needs donor action'] + donations.flagged.count, "needs donor action + flagged != unpaid + unsent: #{values.inspect}"

    donations = Donation.fulfilled.not_sent
    assert_equal donations.count, values['Needs sending by volunteer'] + donations.flagged.count, "needs sending by volunteer + flagged != not sent: #{values.inspect}"

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
    assert_equal values['Average pledge size'], values['Books pledged'].to_f / values['Active pledges'], metrics.inspect
    assert_equal Pledge.active.map {|p| p.donations_count}.sum, values['Donations so far'], metrics.inspect
    assert values['Recurring pledges'] < values['Active pledges'], metrics.inspect
    assert values['Books pledged monthly'] < values['Books pledged'], metrics.inspect
  end

  test "past pledge metrics" do
    metrics = @metrics.past_pledge_metrics
    values = values_for metrics
    assert_equal values['Past pledges'], values['Ended pledges'] + values['Canceled pledges'], metrics.inspect
    assert_equal values['Average past pledge size'], values['Past books pledged'].to_f / values['Past pledges'], metrics.inspect if values['Past pledges'] != 0
    assert_equal Pledge.not_active.map {|p| p.donations_count}.sum, values['Past pledge donations'], metrics.inspect
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
