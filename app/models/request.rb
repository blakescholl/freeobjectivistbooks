# Represents a student's request for a given book.
class Request < ActiveRecord::Base
  attr_accessor :other_book

  # Note that we use 30 and 60 days here instead of 1 and 2 months, because not all months are the same. In Rails,
  # (now - (now - 1.month)) is not necessarily equal to 1.month. Days are constant, as long as you do everything in UTC.
  # -Jason 27 Mar 2013
  RENEW_THRESHOLD = 30.days
  AUTOCANCEL_OPEN_THRESHOLD = 60.days
  AUTOCANCEL_FLAG_THRESHOLD = 7.days

  #--
  # Associations
  #++

  belongs_to :user, autosave: true
  belongs_to :book
  belongs_to :donation
  has_many :donations, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :reminder_entities, as: :entity
  has_many :reminders, through: :reminder_entities
  belongs_to :referral

  Event.create_associations self

  #--
  # Validations
  #++

  validates_presence_of :book, message: "Please choose a book."
  validates_presence_of :reason, message: "This is required."
  validates_acceptance_of :pledge, message: "You must pledge to read this book.", allow_nil: false, on: :create
  validates_presence_of :address, if: :address_required?, message: "We need your address to send you your book."

  #--
  # Scopes and finders
  #++

  default_scope order("created_at desc")

  scope :active, where(canceled: false)
  scope :canceled, where(canceled: true)

  scope :granted, active.where('donation_id is not null')
  scope :not_granted, active.where(donation_id: nil)

  scope :with_prices, joins(:book).merge(Book.with_prices)

  scope :open_longer_than, lambda {|interval| not_granted.where('open_at < ?', Time.now - interval) }
  scope :renewable, open_longer_than(RENEW_THRESHOLD)
  scope :open_too_long, open_longer_than(AUTOCANCEL_OPEN_THRESHOLD)

  def self.flagged_too_long
    Donation.flagged_too_long.includes(:request).map {|donation| donation.request}
  end

  #--
  # Callbacks
  #++

  after_initialize do |request|
    request.open_at ||= Time.now
  end

  before_validation do |request|
    if request.book.nil? && request.other_book.present?
      request.book = Book.find_or_create_by_title request.other_book
    end
  end

  #--
  # Derived attributes
  #++

  delegate :address, :address=, to: :user
  delegate :name, :name=, to: :user, prefix: true
  delegate :status, :thanked?, :sent?, :in_transit?, :received?, :reading?, :read?, :can_send?, :can_flag?, :review,
    :flag, :flagged?, :flagged_at, :needs_fix?, :donor, :fulfiller, :sender, to: :donation, allow_nil: true

  # Alias for the user who created the request.
  def student
    user
  end

  # Whether this request can be granted with a "send-money" donation.
  def can_send_money?
    book.price && book.price > 0 && user.location.country == "United States"
  end

  # Whether the request is active (not canceled).
  def active?
    !canceled?
  end

  # Whether the request has been granted, i.e., has a current donor.
  def granted?
    donation.present?
  end

  # Whether the request is still open, i.e., doesn't have a current donor.
  def open?
    !granted?
  end

  # Whether we're going to require the student to enter an address the next time they update this request.
  def address_required?
    granted? && !flagged?
  end

  # Whether we should prompt the student to thank their donor.
  def needs_thanks?
    granted? && !thanked?
  end

  # The Donation#status, if any.
  def status
    donation ? donation.status : ActiveSupport::StringInquirer.new("")
  end

  def can_update?
    active? && !sent?
  end

  # Whether we will show the student the option to cancel the request.
  def can_cancel?
    !sent? && !canceled?
  end

  # Whether a canceled request can be uncanceled.
  def can_uncancel?
    canceled? && user.can_request?
  end

  # Whether an request can be put back at the top of the list.
  def can_renew?
    open? && Time.since(open_at) > RENEW_THRESHOLD
  end

  # What state this request is in that might subject it to autocancel rules, if any; nil if none.
  # A non-nil value does not indicate that the request is autocancelable; only that it will be if
  # it waits too long in its current state. The can_autocancel? method tells if the threshold has
  # been reached.
  def autocancel_type
    # debugger
    if active? && open?
      :open
    elsif needs_fix?
      :flagged
    end
  end

  # When this request will be autocanceled (if not renewed, for open requests; or unflagged/fixed,
  # for flagged requests).
  def autocancel_at
    case autocancel_type
    when :open then open_at + AUTOCANCEL_OPEN_THRESHOLD
    when :flagged then flagged_at + AUTOCANCEL_FLAG_THRESHOLD
    end
  end

  # Whether the request is ready to be autocanceled.
  def can_autocancel?
    time = autocancel_at
    time && time.past?
  end

  def actions_for(user, options)
    Actions.new self, user, options
  end

  def role_for(user)
    case user
    when student then :student
    when donor then :donor
    when fulfiller then :fulfiller
    end
  end

  # Display title, e.g., for admin detail page
  def title
    "#{user} wants #{book}"
  end

  #--
  # Actions
  #++

  # Grants the request, with the given user as the donor. Returns a new (unsaved) grant event.
  def grant(user)
    self.donation = donations.build(user: user) unless donation && donor == user
    donation.flag = donation.flags.build type: 'missing_address' if address.blank?
    event = donation.grant_events.last unless donation.new_record?
    event || grant_events.build(donation: donation)
  end

  def build_update_event
    update_events.build detail: user.update_detail if user.changed?
  end

  def cancel(params = {})
    return if canceled?
    raise "Can't cancel" if !can_cancel?

    self.canceled = true
    donation.canceled = true if donation
    cancel_request_events.build params[:event]
  end

  # Put this request back at the top of the list and/or uncancel it.
  #
  # The request will be uncanceled if it canceled. The open_at date will be reset to now only if
  # open_at is currently older than the RENEW_THRESHOLD.
  #
  # The request attributes are also updated if supplied, which gives the student a chance to
  # confirm their shipping info for old requests.
  def renew(attributes = {})
    raise "Can't renew granted request" if active? && granted?

    self.attributes = attributes
    if can_uncancel?
      self.canceled = false
      self.donation = nil
    end
    self.open_at = Time.now if can_renew? && attributes[:address].present?

    detail = renew_detail
    renew_events.build detail: detail if detail
  end

  # Auto-cancels an open request if it is past the AUTOCANCEL_OPEN_THRESHOLD.
  def autocancel_if_needed!
    return if canceled?
    return unless can_autocancel?
    type = autocancel_type
    update_attributes! canceled: true
    donation.update_attributes! canceled: true if donation
    autocancel_events.create detail: type.to_s
  end

  #--
  # Helpers
  #++

private

  def renew_detail
    if canceled_changed? && open_at_changed?
      "reopened"
    elsif open_at_changed?
      "renewed"
    elsif canceled_changed?
      "uncanceled"
    end
  end

end
