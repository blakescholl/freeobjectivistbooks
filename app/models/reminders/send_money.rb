# Reminder to a donor to send a contribution for the books that they have promised, if they have any unpaid donations.
class Reminders::SendMoney < Reminder
  def self.new_for_entity(user)
    new user: user, donations: user.donations.needs_payment
  end

  def self.all_key_entities
    User.donors_with_unpaid_donations
  end

  def key_entity
    user
  end

  #--
  # Can send?
  #++

  def too_soon?
    Time.since(donation.created_at) < 3.days
  end

  def min_interval
    4.days
  end

  def max_reminders
    5
  end
end
