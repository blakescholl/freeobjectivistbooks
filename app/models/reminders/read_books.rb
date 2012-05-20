class Reminders::ReadBooks < Reminder
  def self.new_for_entity(donation)
    new user: donation.student, donations: [donation]
  end

  def self.all_key_entities
    Donation.reading
  end

  def key_entity
    donation
  end

  # Can send?

  def too_soon?
    Time.since(donation.received_at) < 1.month
  end

  def min_interval
    1.month
  end

  def max_reminders
    6
  end
end
