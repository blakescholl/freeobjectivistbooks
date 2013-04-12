# Represents a group of Donations that a donor paid for with a new Contribution and/or an outstanding balance.
class Order < ActiveRecord::Base
  include ActionView::Helpers::TextHelper

  monetize :total_cents
  monetize :balance_applied_cents, allow_nil: true
  monetize :new_contribution_cents, allow_nil: true

  belongs_to :user
  has_many :donations
  has_many :contributions

  validates_presence_of :user
  validate :donations_belong_to_user
  validate :donations_are_all_eligible

  after_initialize :populate

  def balance_to_be_applied
    [total, user.balance].min
  end

  def new_contribution_needed
    total - balance_to_be_applied
  end

  # Options to be passed to an AmazonPayment.
  def payment_options
    {amount: new_contribution_needed, reference_id: id, description: description}
  end

private
  def donations_belong_to_user
    errors.add :user, "doesn't own all these donations" if donations.any? {|donation| donation.user != user}
  end

  def donations_are_all_eligible
    if !donations.all? {|donation| donation.can_send_money?}
      errors.add :base, "not all donations eligible for volunteer sending"
    end
  end

  def populate
    return if id
    self.total = donations.map {|donation| donation.price}.compact.sum
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
