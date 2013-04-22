# Represents a pledge by a donor to donate a specific number of books.
class Pledge < ActiveRecord::Base
  belongs_to :user
  belongs_to :referral
  has_many :events
  has_many :reminder_entities, as: :entity
  has_many :reminders, through: :reminder_entities
  has_one :testimonial, as: :source

  Event.create_associations self

  validates_numericality_of :quantity, only_integer: true, greater_than: 0,
    message: "Please enter a number of books to pledge."

  default_scope order("created_at desc")

  scope :active, where(canceled: false)

  def active?
    !canceled?
  end

  # Returns all unfulfilled pledges.
  def self.unfulfilled
    active.includes(:user).select {|pledge| !pledge.fulfilled? }
  end

  # Determines if the donor has donated at least as many books as pledged.
  def fulfilled?
    user.donations.active.count >= quantity
  end

  def update_detail
    "quantity from #{quantity_was} to #{quantity}"
  end

  def build_update_event
    update_events.build detail: update_detail if changed?
  end

  def cancel(params = {})
    return if canceled?
    self.canceled = true
    cancel_pledge_events.build params[:event]
  end

  # Creates a Testimonial based on this pledge and its "reason" text.
  def to_testimonial
    Testimonial.new source: self, type: 'donor', title: "From a donor", text: reason, attribution: "#{user.name}, #{user.location}"
  end
end
