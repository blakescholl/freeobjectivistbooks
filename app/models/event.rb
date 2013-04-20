# Represents an action taken by the student or donor in the lifecycle of a Request.
class Event < ActiveRecord::Base
  self.inheritance_column = 'class'  # anything other than "type", to let us use "type" for something else

  TYPES = %w{grant update flag fix message update_status cancel_donation cancel_request renew autocancel}

  #--
  # Associations
  #++

  belongs_to :user
  belongs_to :request
  belongs_to :donation
  belongs_to :pledge
  belongs_to :recipient, class_name: "User"
  belongs_to :reply_to_event, class_name: "Event"
  has_one :testimonial, as: :source

  #--
  # Validations
  #++

  validates_presence_of :request, :type
  validates_presence_of :donation, if: lambda {|e| e.type.in? %w{grant flag fix message update_status cancel_donation}}
  validates_inclusion_of :type, in: TYPES

  validates_presence_of :message, if: :requires_message?, message: "Please enter a message."
  validates_inclusion_of :public, in: [true, false], if: :is_thanks?, message: 'Please choose "Yes" or "No".'
  validate :message_or_detail_must_be_present, if: lambda {|e| e.type == "fix" && e.request.address.present?}
  validates_inclusion_of :recipient, in: lambda {|e| e.potential_recipients}, allow_nil: true, message: "Please choose a recipient."
  validate :reply_to_event_must_match, if: :reply_to_event

  def requires_message?
    case type
    when "flag", "message" then true
    when "cancel_donation" then detail != "not_received"
    else false
    end
  end

  def message_or_detail_must_be_present
    if detail.blank? && message.blank?
      errors[:message] << "If you don't need to update your shipping info, please enter a message for your donor."
    end
  end

  def reply_to_event_must_match
    if reply_to_event.request != request
      errors[:reply_to_event] << "Request doesn't match."
    elsif reply_to_event.donation != donation
      errors[:reply_to_event] << "Donation doesn't match."
    end
  end

  #--
  # Scopes
  #++

  default_scope order(:happened_at)

  scope :reverse_order, reorder('happened_at desc')
  scope :public_thanks, where(is_thanks: true, public: true)

  #--
  # Callbacks
  #++

  after_initialize :populate

  after_create :update_thanked
  after_create :log
  after_create :notify

  def populate
    unless id
      self.donation ||= request.donation if request
      self.request ||= donation.request if donation
      self.user ||= default_user
      self.happened_at ||= Time.now
    end
  end

  def default_user
    case type
    when "grant", "flag" then donor
    when "update", "fix", "cancel_request", "renew" then student
    when "update_status"
      case detail
      when "sent" then donor
      when "received", "read" then student
      end
    else
      student if is_thanks?
    end
  end
  private :default_user

  #--
  # Derived attributes
  #++

  delegate :book, :student, to: :request
  delegate :donor, :fulfiller, :sender, to: :donation, allow_nil: true

  def role_for(user)
    case user
    when student then :student
    when donor then :donor
    when fulfiller then :fulfiller
    end
  end

  def user_role
    role_for user
  end

  def is_private?
    recipient.present?
  end

  def gets_private_reply?
    is_private? || is_thanks? || (type == "update_status" && user == student)
  end

  def all_users
    [student, donor, fulfiller].compact.uniq
  end

  def other_users
    all_users - [user]
  end

  def potential_recipients
    if type.in? %w{update fix}
      [sender].compact
    elsif type == "message" && reply_to_event && reply_to_event.gets_private_reply?
      [reply_to_event.user]
    else
      other_users
    end
  end

  def recipients
    recipient.present? ? [recipient] : potential_recipients
  end

  # True if the notification for this event has been sent.
  def notified?
    notified_at.present?
  end

  #--
  # Actions
  #++

  # Marks the event as notified.
  def notified
    self.notified_at = Time.now
  end

  # Marks the event as notifies and saves.
  def notified!
    notified
    save!
  end

  # Sends a notification email for this event.
  def notify
    return if notified?
    recipients.each do |recipient|
      mail = EventMailer.mail_for_event self, recipient
      Rails.logger.info "Sending notification for event #{id} (#{type} #{detail}) to #{recipient} (#{mail.to})"
      mail.deliver
    end
    self.notified!
  end

  def update_thanked
    donation.update_attributes! thanked: true if is_thanks?
  end

  def log
    Rails.logger.info "Event: #{inspect}"
  end

  #--
  # Conversions
  #++

  def to_testimonial
    Testimonial.new source: self, type: 'student', title: "A thank-you", text: message,
      attribution: "#{student.name}, studying #{student.studying.downcase} at #{student.school}, to donor #{donor.name}"
  end
end
