# A reminder/suggestion to a student with an open request to renew their request.
class Reminders::RenewRequest < Reminder
  def self.new_for_entity(request)
    new user: request.user, requests: [request]
  end

  def self.all_key_entities
    Request.renewable.includes(:user)
  end

  def key_entity
    request
  end

  #--
  # Can send?
  #++

  def too_soon?
    !request.can_renew?
  end

  def min_interval
    30.days
  end

  def max_reminders
    1
  end

  def reminder_count_reset_at
    request.open_at
  end
end
