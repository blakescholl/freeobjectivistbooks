# Reminder to a donor to send the specific books that they have promised, if they haven't yet
# confirmed that they have done so.
class Reminders::SendBooks < Reminder
  def self.new_for_entity(user)
    new user: user, donations: user.donations.needs_donor_action
  end

  def self.all_key_entities
    User.donors_with_outstanding_donations
  end

  def key_entity
    user
  end

  #--
  # Can send?
  #++

  def min_interval
    4.days
  end

  def max_reminders
    5
  end
end
