class Contribution < ActiveRecord::Base
  monetize :amount_cents

  belongs_to :user

  validates_presence_of :user, :amount_cents

  after_create :add_to_user_balance
  after_destroy :subtract_from_user_balance

  def add_to_user_balance
    user.balance += amount
    user.save!
  end

  def subtract_from_user_balance
    user.balance -= amount
    user.save!
  end
end
