class Contribution < ActiveRecord::Base
  monetize :amount_cents

  belongs_to :user
  belongs_to :order

  validates_presence_of :user, :amount_cents

  def self.create_from_amazon_ipn(params)
    return nil if !AmazonPayment.success_status?(params['status'])
    contribution = find_or_initialize_by_transaction_id params['transactionId']
    contribution.user_id = params['referenceId'].to_i
    contribution.amount = Money.parse params['transactionAmount']
    contribution.save!
  end

  def add_to_user_balance
    user.balance += amount
    user.save!
  end

  def subtract_from_user_balance
    user.balance -= amount
    user.save!
  end

  def title
    "#{user.name}, #{amount.format}"
  end
end
