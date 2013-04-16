# A note sent to a student when the donor hasn't confirmed that they have sent the book. Asks
# if they have recieved the book, but gives them the option to cancel the donation if not (in
# which case they go back on the open requests list to try to find another donor.)
class Reminders::ConfirmReceiptUnsent < Reminder
  def self.new_for_entity(donation)
    new user: donation.student, donations: [donation]
  end

  def self.all_key_entities
    Donation.needs_donor_action.includes(request: :user)
  end

  def key_entity
    donation
  end

  #--
  # Can send?
  #++

  def too_soon?
    !donation.student_can_cancel?
  end

  def min_interval
    1.week
  end

  def max_reminders
    3
  end
end
