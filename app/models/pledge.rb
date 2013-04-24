# Represents a pledge by a donor to donate a specific number of books.
class Pledge < ActiveRecord::Base
  PLEDGE_PERIOD = 1.month

  belongs_to :user
  has_many :donations
  has_many :events
  has_many :reminder_entities, as: :entity
  has_many :reminders, through: :reminder_entities
  has_one :testimonial, as: :source
  belongs_to :referral

  Event.create_associations self

  validates_numericality_of :quantity, only_integer: true, greater_than: 0,
    message: "Please enter a number of books to pledge."

  default_scope order("created_at desc")

  scope :not_canceled, where(canceled: false)
  scope :active, not_canceled.where(ended: false)
  scope :needs_ending, lambda {active.where('created_at < ?', PLEDGE_PERIOD.ago)}

  def active?
    !canceled? && !ended?
  end

  # Returns all unfulfilled pledges.
  def self.unfulfilled
    active.includes(:user).select {|pledge| !pledge.fulfilled? }
  end

  def donations_count
    donations.active.size
  end

  # Determines if the donor has donated at least as many books as pledged.
  def fulfilled?
    donations_count >= quantity
  end

  def exceeded?
    donations_count > quantity
  end

  def any_donations?
    donations_count > 0
  end

  def status
    if exceeded?
      :exceeded
    elsif fulfilled?
      :fulfilled
    elsif any_donations?
      :partial
    else
      :empty
    end
  end

  def update_detail
    "quantity from #{quantity_was} to #{quantity}"
  end

  def build_update_event
    update_events.build detail: update_detail if changed?
  end

  def needs_ending?
    active? && created_at < PLEDGE_PERIOD.ago
  end

  def end_if_needed!
    return unless needs_ending?

    self.ended = true
    save!

    if recurring?
      new_pledge = Pledge.create! user: user, quantity: quantity, recurring: true
      mail = PledgeMailer.pledge_autorenewed self, new_pledge
    else
      mail = PledgeMailer.pledge_ended self
      new_pledge = nil
    end

    mail.deliver

    new_pledge
  end

  def cancel(params = {})
    return if !active?
    self.canceled = true
    cancel_pledge_events.build params[:event]
  end

  # Creates a Testimonial based on this pledge and its "reason" text.
  def to_testimonial
    Testimonial.new source: self, type: 'donor', title: "From a donor", text: reason, attribution: "#{user.name}, #{user.location}"
  end
end
