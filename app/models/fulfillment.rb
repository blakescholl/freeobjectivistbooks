class Fulfillment < ActiveRecord::Base
  belongs_to :user
  belongs_to :donation

  delegate :book, :student, :donor, :address, :request, :needs_sending?, to: :donation

  scope :needs_sending, joins(:donation).merge(Donation.needs_sending)
  scope :flagged, joins(:donation).merge(Donation.flagged)
  scope :sent, joins(:donation).merge(Donation.sent)
end
