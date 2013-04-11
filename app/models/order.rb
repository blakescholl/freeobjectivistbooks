# Represents a group of Donations that a donor paid for with a new Contribution and/or an outstanding balance.
class Order < ActiveRecord::Base
  include ActionView::Helpers::TextHelper

  monetize :subtotal_cents
  monetize :balance_applied_cents
  monetize :total_cents

  belongs_to :user
  has_many :donations
  has_many :contributions

  validates_presence_of :user
  validate :donations_belong_to_user

  after_initialize :populate

  # Options to be passed to an AmazonPayment.
  def payment_options
    {amount: total, reference_id: id, description: description}
  end

private
  def donations_belong_to_user
    donations.any? {|donation| donation.user != user}
  end

  def populate
    return if id
    self.subtotal = donations.map {|donation| donation.price}.sum
    self.balance_applied = [subtotal, user.balance].min
    self.total = subtotal - balance_applied
    self.description ||= default_description
  end

  def default_description
    donation = donations.first
    description = "#{donation.book} to #{donation.student} in #{donation.student.location}"
    rest = donations.size - 1
    description += " and " + pluralize(rest, "more book") if rest > 0
    description
  end
end
