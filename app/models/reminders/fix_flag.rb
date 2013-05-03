# A reminder to a student to respond to a flagged donation.
class Reminders::FixFlag < Reminder
  def self.new_for_entity(flag)
    new user: flag.student, flags: [flag], donations: [flag.donation]
  end

  def self.all_key_entities
    Donation.needs_fix.includes(:flag).map {|d| d.flag}
  end

  def key_entity
    flag
  end

  #--
  # Can send?
  #++

  def too_soon?
    Time.since(flag.created_at) < 1.days
  end

  def min_interval
    2.days
  end

  def max_reminders
    3
  end
end
