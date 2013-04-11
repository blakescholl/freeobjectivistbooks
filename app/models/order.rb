class Order < ActiveRecord::Base
  monetize :subtotal_cents
  monetize :balance_applied_cents
  monetize :total_cents

  belongs_to :user
  has_many :donations
  has_many :contributions
end
