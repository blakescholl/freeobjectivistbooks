class AnnouncementMailer < ApplicationMailer
  def announcement(subject, options = {})
    mail_to_user @user, options.merge(subject: subject)
  end

  def thank_your_donor(request)
    @request = request
    @user = @request.user
    announcement "Thank your donor for #{@request.book}"
  end

  def reply_to_thanks(event)
    @event = event
    @user = @event.donor
    announcement "Now you can reply to #{@event.user}'s thank-you note on Free Objectivist Books"
  end

  def mark_sent_books(user)
    @user = user
    @count = user.donations.active.count
    announcement "Have you sent your Objectivist books? Let me and the students know"
  end

  def mark_received_books(request)
    @request = request
    @user = request.user
    @sent_event = request.update_status_events.where(detail: "sent").last
    announcement "Have you received #{request.book}? Let us and your donor know"
  end

  def mark_read_books(donation)
    @donation = donation
    @user = donation.student
    @received_at = donation.received_at
    announcement "Let us know when you finish reading #{donation.book}"
  end
end
