# Reminder to a volunteer to fulfill donations.
class Reminders::FulfillDonations < Reminder
  def self.new_for_entity(user)
    new user: user
  end

  def self.all_key_entities
    User.volunteer
  end

  def key_entity
    user
  end

  #--
  # Can send?
  #++

  def too_soon?
    return true if Donation.needs_fulfillment.empty?
    last_fulfillment = user.fulfillments.reorder(:created_at).last
    last_fulfillment && Time.since(last_fulfillment.created_at) < 3.days
  end

  def min_interval
    3.days
  end

  def max_reminders
    nil
  end
end
