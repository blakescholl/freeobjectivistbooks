# Represents a donor's granting of a student's request (or stated intention to do so).
class Donation < ActiveRecord::Base
  # Thrown when we try to fulfill a donation that is already fulfilled.
  class AlreadyFulfilled < StandardError; end

  monetize :price_cents, allow_nil: true

  #--
  # Associations
  #++

  belongs_to :request, autosave: true
  belongs_to :user
  belongs_to :pledge
  has_many :events, dependent: :destroy
  belongs_to :flag
  has_many :flags, dependent: :destroy
  belongs_to :order
  has_one :fulfillment
  has_one :review
  has_many :reminder_entities, as: :entity
  has_many :reminders, through: :reminder_entities

  Event.create_associations self

  #--
  # Validations
  #++

  validates_presence_of :request
  validates_presence_of :user
  validates_presence_of :address, if: :needs_address?, message: "We need your address to send you your book."
  validates_inclusion_of :status, in: %w{not_sent sent received read}
  validates_uniqueness_of :request_id, scope: :canceled, if: :active?, message: "has already been granted", on: :create
  validate :donor_cannot_be_requester, on: :create
  validate :order_belongs_to_user, if: :order
  validate :pledge_belongs_to_user, if: :pledge

  def donor_cannot_be_requester
    errors.add :base, "You can't donate to yourself!" if donor == student
  end

  def order_belongs_to_user
    errors.add :order, "doesn't belong to this user" if order.user != user
  end

  def pledge_belongs_to_user
    errors.add :pledge, "doesn't belong to this user" if pledge.user != user
  end

  #--
  # Scopes and pseudo-scopes
  #++

  default_scope order("created_at desc")

  scope :active, where(canceled: false)
  scope :canceled, where(canceled: true)

  scope :thanked, active.where(thanked: true)
  scope :not_thanked, active.where(thanked: false)

  scope :flagged, active.where('flag_id is not null')
  scope :not_flagged, active.where(flag_id: nil)

  scope :paid, active.where(paid: true)
  scope :unpaid, active.where(paid: false)
  scope :has_price, where('price_cents is not null')

  scope :fulfilled, joins(:fulfillment)
  scope :unfulfilled, joins('left join fulfillments on fulfillments.donation_id = donations.id').where('fulfillments.id is null')

  scope :not_sent, active.scoped_by_status("not_sent")
  scope :sent, active.scoped_by_status(%w{sent received read})
  scope :in_transit, active.scoped_by_status("sent")
  scope :received, active.scoped_by_status(%w{received read})
  scope :reading, active.scoped_by_status("received")
  scope :read, active.scoped_by_status("read")

  scope :needs_sending, active.not_flagged.not_sent
  scope :needs_thanks, active.received.not_thanked
  scope :needs_fulfillment, active.needs_sending.paid.unfulfilled

  scope :needs_donor_action, active.unpaid.not_flagged.not_sent

  def self.no_donor_action
    t = arel_table
    flagged = t[:flag_id].not_eq nil
    paid = t[:paid].eq true
    sent = t[:status].not_eq 'not_sent'
    active.where(flagged.or paid.or sent)
  end

  #--
  # Callbacks
  #++

  before_validation do |donation|
    if donation.status.blank?
      donation.status = "not_sent"
      donation.status_updated_at = donation.created_at
    end
  end

  before_create do |donation|
    donation.price = donation.book.price
    donation.pledge = donation.user.current_pledge
  end

  #--
  # Derived attributes
  #++

  delegate :book, :can_send_money?, :address, to: :request

  # Whether the donation is still active, i.e., not canceled.
  def active?
    !canceled?
  end

  # Alias for the user who made the donation.
  def donor
    user
  end

  # Student the donation is for.
  def student
    request.user
  end

  # User who fulfilled this donation, if not the donor.
  def fulfiller
    fulfillment.user if fulfillment
  end

  # User who is responsible for sending the book.
  def sender
    paid? ? fulfiller : donor
  end

  def fulfilled?
    fulfillment.present?
  end

  # Status of the donation: not_sent, sent, received, or read, as a StringInquirer.
  def status
    ActiveSupport::StringInquirer.new(self[:status] || "")
  end

  # True if the book has been sent. (This is not the same as status = sent, since it is still true
  # after the book has been received.)
  def sent?
    status.sent? || status.received? || status.read?
  end

  # True if the book has been sent but not yet received.
  def in_transit?
    status.sent?
  end

  # True if the book has been received.
  def received?
    status.received? || status.read?
  end

  # True if the book has been received but not yet read.
  def reading?
    status.received?
  end

  # True if the book has been read.
  def read?
    status.read?
  end

  # True if the donation has a current, active flag indicating a problem with shipping.
  def flagged?
    flag.present?
  end

  # Whether we're going to require the student to enter an address the next time they update the
  # associated request.
  def needs_address?
    !flagged? && !sent?
  end

  # Whether the donation has been flagged for the student to respond.
  def needs_fix?
    active? && flagged?
  end

  # True if the ball is in the sender's court to send the book.
  def needs_sending?
    !sent? && !flagged?
  end

  # True if this is an "outstanding" donation that the donor needs to do something with--either send or pay for.
  def needs_donor_action?
    needs_sending? && !paid?
  end

  # True if we should show the "sent" button to the donor.
  def can_send?
    !sent?
  end

  # True if we should show the "flag" link to the donor.
  def can_flag?
    !sent? && !flagged?
  end

  # True if the donor can cancel the donation.
  def donor_can_cancel?
    !received? && !paid?
  end

  # True if the student is allowed to cancel the donation.
  def student_can_cancel?
    needs_donor_action? && Time.since(created_at) >= 3.weeks
  end

  # True if the given user can cancel the donation.
  def can_cancel?(user)
    case user
    when donor then donor_can_cancel?
    when student then student_can_cancel?
    else false
    end
  end

  def updated_at_for_status(status)
    return created_at if status == "not_sent"

    event = update_status_events.where(detail: status).last
    if event
      event.happened_at
    elsif self.status == status
      updated_at
    end
  end
  private :updated_at_for_status

  # The time the book was confirmed sent, if any.
  def sent_at
    updated_at_for_status "sent"
  end

  # The time the book was confirmed received, if any.
  def received_at
    updated_at_for_status "received"
  end

  # The time the book was confirmed read, if any.
  def read_at
    updated_at_for_status "read"
  end

  def role_for(user)
    case user
    when student then :student
    when donor then :donor
    when fulfiller then :fulfiller
    end
  end

  #--
  # Actions
  #++

  def pay_if_covered
    return unless can_send_money? && price.present?
    return if paid?
    self.paid = user.decrement_balance_if_covered! price
    save!
  end

  def unpay
    return if price.nil?
    return if !paid?
    user.increment_balance! price
    self.paid = false
    save!
  end

  def fulfill(user)
    if !fulfillment
      create_fulfillment user: user
    elsif fulfillment.user == user
      fulfillment
    else
      raise AlreadyFulfilled
    end
  end

  def update_status(params, user = nil, time = Time.now)
    self.status = params[:status]
    self.status_updated_at = time
    self.flag = nil if sent?

    event_attributes = params[:event] || {}
    event_attributes = event_attributes.merge(user: user) if user
    event_attributes = event_attributes.merge(happened_at: time, detail: params[:status])
    event = update_status_events.build event_attributes
    if event.message.blank?
      event.is_thanks = nil
      event.public = nil
    end
    event
  end

  def new_message(user, attributes = {})
    event = message_events.build attributes.merge(user: user)
    if event.reply_to_event
      event.recipient = event.reply_to_event.user
    elsif user != student
      event.recipient = student
    end
    event
  end

  def add_flag(params, user = nil)
    params = params.merge user: user
    self.flag = flags.build params
    flag_events.build flag: self.flag
  end

  def cancel(params, user)
    return if canceled?
    raise "Can't cancel" unless can_cancel? user
    self.canceled = true
    if request.donation == self
      request.donation = nil
      request.open_at = Time.now
      cancel_donation_events.build params[:event].merge(user: user)
    end
  end

  #--
  # Conversions
  #++

  def as_json(options = {})
    hash_from_methods :id, :donor, :student, :book, :price_cents, :can_send_money?
  end
end
