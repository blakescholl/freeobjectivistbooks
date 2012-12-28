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
  has_many :events, dependent: :destroy
  has_one :fulfillment
  has_one :review
  has_many :reminder_entities, as: :entity
  has_many :reminders, through: :reminder_entities

  Event::TYPES.each do |type|
    define_method "#{type}_events" do
      events.scoped_by_type type
    end
  end

  #--
  # Validations
  #++

  validates_presence_of :request
  validates_presence_of :user
  validates_presence_of :address, if: :needs_address?, message: "We need your address to send you your book."
  validates_inclusion_of :status, in: %w{not_sent sent received read}
  validates_inclusion_of :donor_mode, in: User::DONOR_MODES
  validates_uniqueness_of :request_id, scope: :canceled, if: :active?, message: "has already been granted", on: :create
  validate :donor_cannot_be_requester, on: :create

  def donor_cannot_be_requester
    errors.add :base, "You can't donate to yourself!" if donor == student
  end

  #--
  # Scopes
  #++

  default_scope order("created_at desc")

  scope :active, where(canceled: false)
  scope :canceled, where(canceled: true)

  scope :thanked, active.where(thanked: true)
  scope :not_thanked, active.where(thanked: false)

  scope :flagged, active.where(flagged: true)
  scope :not_flagged, active.where(flagged: false)

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

  scope :send_money, scoped_by_donor_mode('send_money')
  scope :send_books, scoped_by_donor_mode('send_books')

  scope :needs_sending, active.not_flagged.not_sent
  scope :needs_thanks, active.received.not_thanked
  scope :needs_payment, active.send_money.unpaid
  scope :needs_fulfillment, active.needs_sending.paid.unfulfilled

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
    donation.donor_mode = user.donor_mode if donation.price
  end

  #--
  # Derived attributes
  #++

  delegate :book, to: :request
  delegate :address, :address=, to: :student
  delegate :name, :name=, to: :student, prefix: true

  def donor_mode
    ActiveSupport::StringInquirer.new(self[:donor_mode])
  end

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

  # Whether we're going to require the student to enter an address the next time they update the
  # associated request.
  def needs_address?
    !flagged? && !sent?
  end

  # Whether the donation has been flagged for the student to respond.
  def needs_fix?
    active? && flagged?
  end

  # True if the ball is in the donor's court to send the book.
  def needs_sending?
    !sent? && !flagged?
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
    return false if sent? || flagged? || donor_mode.send_money? || Time.since(created_at) < 3.weeks
    reminder = reminders.where(type: Reminders::SendBooks).reorder(:created_at).first
    reminder && Time.since(reminder.created_at) >= 1.week
  end

  # True if the given user can cancel the donation.
  def can_cancel?(user)
    case user
    when donor then donor_can_cancel?
    when student then student_can_cancel?
    else false
    end
  end

  # The most recent flag event, if any.
  def flag_event
    flag_events.last
  end

  # The message from the donor the last time the donor flagged the request, if any.
  def flag_message
    event = flag_event
    event.message if event
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

  #--
  # Actions
  #++

  def pay_if_covered
    return unless donor_mode.send_money? && price.present?
    return if paid?
    if user.balance >= price
      user.balance -= price
      user.save!
      self.paid = true
      save!
    end
  end

  def unpay
    return if !paid?
    user.balance += price
    user.save!
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
    self.flagged = false if sent?

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

  def flag(params, user = nil)
    self.flagged = true
    params = params.merge(user: user) if user
    flag_events.build params
  end

  def fix(attributes, event_attributes = {})
    self.attributes = attributes
    self.flagged = false
    fix_events.build event_attributes.merge(detail: student.update_detail)
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
end
