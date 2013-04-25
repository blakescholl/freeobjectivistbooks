# Represents a group of Donations that a donor paid for with a new Contribution and/or an outstanding balance.
class Order < ActiveRecord::Base
  include ActionView::Helpers::TextHelper

  belongs_to :user
  has_many :donations
  has_many :contributions

  validates_presence_of :user
  validate :donations_belong_to_user
  validate :contributions_belong_to_user

  # Donations in this order that are eligible to be paid for (should be all of them)
  def eligible_donations
    donations.select &:can_send_money?
  end

  # Eligible Donations that have not yet be paid for.
  def unpaid_donations
    eligible_donations.reject &:paid?
  end

  # True iff all the (eligible) Donations in this order have been paid for.
  def paid?
    unpaid_donations.empty?
  end

  # Total for all eligible donations in this order.
  def total
    donations_total eligible_donations
  end

  # Total needed to finish paying for this order.
  def unpaid_total
    donations_total unpaid_donations
  end

  # Existing user balance that will be applied to pay for this order. If less than the total, then
  # a new Contribution will be needed.
  def balance
    [unpaid_total, user.balance].min
  end

  # New Contribution needed to cover this order.
  def contribution
    unpaid_total - balance
  end

  # Whether a new Contribution is needed to cover the Donations.
  def needs_contribution?
    contribution > 0
  end

  # Title for, e.g., admin interface
  def title
    "#{donations.size} books, total $#{total}"
  end

  # Summary of the Donations in this order.
  def description
    return "(empty)" if donations.empty?
    donation = donations.first
    description = "#{donation.book} to #{donation.student} in #{donation.student.location}"
    rest = donations.size - 1
    description += " and " + pluralize(rest, "more book") if rest > 0
    description
  end

  # Options to be passed to an AmazonPayment.
  def payment_options
    {amount: contribution, reference_id: user.id, description: description}
  end

  # Pays for all donations, or as many as are covered by the user's current balance.
  def pay!
    donations.each &:pay_if_covered
  end

private
  def donations_total(donations)
    donations.map(&:price).sum
  end

  def donations_belong_to_user
    errors.add :user, "doesn't own all these donations" if donations.any? {|donation| donation.user != user}
  end

  def contributions_belong_to_user
    errors.add :user, "doesn't own all these contributions" if contributions.any? {|contribution| contribution.user != user}
  end
end
