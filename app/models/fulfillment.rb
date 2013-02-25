class Fulfillment < ActiveRecord::Base
  belongs_to :user
  belongs_to :donation

  delegate :book, :student, :donor, :address, :request, to: :donation

  scope :needs_sending, joins(:donation).merge(Donation.needs_sending)
end
