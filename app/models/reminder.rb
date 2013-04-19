# Represents a reminder email sent to a user, e.g., when the ball is in their court to take the
# next action on a Donation, or when they need to fulfill a Pledge. Used by the ReminderMailer.
#
# This is an "abstract" superclass, "implemented" by subclasses in the Reminders module.
class Reminder < ActiveRecord::Base
  def self.type_name
    name.demodulize.underscore
  end

  #--
  # Associations
  #++

  belongs_to :user
  has_many :reminder_entities, dependent: :destroy
  has_many :pledges, through: :reminder_entities, source: :entity, source_type: 'Pledge'
  has_many :requests, through: :reminder_entities, source: :entity, source_type: 'Request'
  has_many :donations, through: :reminder_entities, source: :entity, source_type: 'Donation'

  #--
  # Scopes
  #++

  default_scope order(:created_at)

  #--
  # Constructors
  #++

  # Creates a new reminder based on the given "key entity". Must be overridden by subclasses.
  def self.new_for_entity(entity)
    raise NotImplementedError
  end

  # Finds all "key entities" that are eligible for reminders. Should be overridden by subclasses.
  def self.all_key_entities
    []
  end

  # Builds a set of Reminder objects based on all_key_entities.
  #
  # May include Reminders that shouldn't actually be sent right now, e.g., because we just sent
  # one, or because we've sent too many total. Use can_send? to determine if a reminder should
  # actually be sent.
  def self.all_reminders
    all_key_entities.map {|entity| new_for_entity entity}
  end

  #--
  # Configuration to be overridden by subclasses
  #++

  # The primary entity that this reminder is for. The min_interval and max_reminders restrictions
  # are in relation to this entity. Must be overridden by subclasses.
  def key_entity
    nil
  end

  # Whether it is too soon to send this reminder. May be overridden by subclasses.
  def too_soon?
    false
  end

  # The minimum amount of time to wait between reminders for the same entity. May be overridden by subclasses.
  def min_interval
    1.week
  end

  # The maximum amount of this type of reminder to send for a given entity, if any. May be overridden by subclasses.
  # A value of nil means there is no maximum and reminders can continue indefinitely (generally not recommended).
  def max_reminders
    3
  end

  # The datetime at which the reminder count reset, for the purpose of applying the max_reminders restriction. If
  # non-nil, then only reminders created after this time are counted against max_reminders. Otherwise, there is no
  # reset, and all past reminders are counted. May be overridden by subclasses.
  def reminder_count_reset_at
    nil
  end

  #--
  # Derived attributes
  #++

  def pledge
    pledges.first
  end

  def request
    requests.first
  end

  def donation
    donations.first
  end

  # The most recent reminder of this type sent for the key_entity.
  def latest_reminder
    key_entity.reminders.where(type: type, user_id: user).reorder(:created_at).last
  end

  # The total number of reminders of this type that have been sent for any of the related Donations
  # or Pledges.
  def past_reminder_count
    # We want the minimum past reminder count among all entities this reminder is for.
    entities = donations + requests + pledges
    return 0 if entities.empty?

    reset_at = reminder_count_reset_at

    counts = entities.map do |entity|
      reminders = entity.reminders.where(type: type, user_id: user)
      reminders = reminders.where('reminders.created_at >= ?', reset_at) if reset_at
      reminders.count
    end
    counts.min
  end

  # True if this reminder should actually be sent.
  #
  # May be false, e.g., if we just sent one of these reminders, or if we've sent too many reminders
  # for the same thing.
  def can_send?
    if too_soon?
      Rails.logger.info "Too soon for #{self}"
      return false
    end

    latest = latest_reminder
    if latest && Time.since(latest.created_at) < min_interval
      Rails.logger.info "Just sent #{self} at #{latest.created_at}"
      return false
    end

    if max_reminders
      count = past_reminder_count
      if count >= max_reminders
        Rails.logger.info "Already sent #{count} of #{self}"
        return false
      end
    end

    true
  end

  def to_s
    "#{type.demodulize} re #{key_entity.class} #{key_entity.id}"
  end
end
