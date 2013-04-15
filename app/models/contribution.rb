class Contribution < ActiveRecord::Base
  monetize :amount_cents

  belongs_to :user
  belongs_to :order

  validates_presence_of :user, :amount_cents
  validate :order_belongs_to_user, if: :order

  after_initialize :populate

  def self.find_or_initialize_from_amazon_ipn(params)
    return nil if !AmazonPayment.success_status?(params['status'])
    contribution = find_or_initialize_by_transaction_id params['transactionId']
    contribution.user_id = params['referenceId'].to_i
    contribution.amount = Money.parse params['transactionAmount']
    contribution
  end

  def add_to_user_balance
    user.increment_balance! amount
  end

  def subtract_from_user_balance
    user.decrement_balance! amount
  end

  def title
    "#{user.name}, #{amount.format}"
  end

  private
  def populate
    return if id
    if order
      self.user ||= order.user
      self.amount ||= order.contribution
    end
  end

  def order_belongs_to_user
    errors.add :order, "doesn't belong to this user" if order.user != user
  end
end
