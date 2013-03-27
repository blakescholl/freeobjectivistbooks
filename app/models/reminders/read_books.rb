# Reminder to a student to read their book and confirm that they have read it.
class Reminders::ReadBooks < Reminder
  def self.new_for_entity(donation)
    new user: donation.student, donations: [donation]
  end

  def self.all_key_entities
    Donation.reading.includes(request: :user)
  end

  def key_entity
    donation
  end

  #--
  # Can send?
  #++

  def too_soon?
    Time.since(donation.received_at) < 30.days
  end

  def min_interval
    30.days
  end

  def max_reminders
    6
  end
end
