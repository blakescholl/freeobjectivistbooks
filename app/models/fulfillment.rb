class Fulfillment < ActiveRecord::Base
  belongs_to :user
  belongs_to :donation

  delegate :book, :student, :donor, :address, :request, to: :donation
end
