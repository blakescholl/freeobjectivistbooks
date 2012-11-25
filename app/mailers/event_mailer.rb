class EventMailer < ApplicationMailer
  def self.mail_for_event(event)
    self.send "#{event.type}_event", event
  end

  def notification(subject, options = {})
    template = options[:template_name] || "#{@event.type}_event"
    role = @event.to_student? ? "student" : "donor"
    options[:template_name] = "#{role}/#{template}"
    mail_to_user @event.to, options.merge(subject: subject)
  end

  def grant_event(event)
    @event = event
    @closer = "Happy reading"
    notification "We found a donor to send you #{@event.book}!"
  end

  def update_event(event)
    @event = event
    notification "#{@event.user.name} #{@event.detail} for #{@event.book}"
  end

  def flag_event(event)
    @event = event
    notification "Problem with your shipping info for #{@event.book}"
  end

  def fix_event(event)
    @event = event
    action = event.detail || "responded to your flag"
    notification "#{@event.user.name} #{action} for #{@event.book}"
  end

  def message_event(event)
    @event = event
    message_type = event.is_thanks? ? "thank-you note for #{@event.book}" : "message about #{@event.book}"
    notification "#{@event.user.name} sent you a #{message_type}"
  end

  def update_status_event(event)
    @event = event
    @review = event.donation.review
    @closer = "Happy reading" if event.to_student? && event.donation.sent?
    notification "#{@event.user.name} has #{@event.detail} #{@event.book}", template_name: "#{@event.detail}_event"
  end

  def cancel_donation_event(event)
    @event = event
    @closer = "Yours"
    case @event.to
    when @event.student
      notification "We need to find you a new donor for #{@event.book}"
    when @event.donor
      notification "Your donation of #{@event.book} to #{@event.student.name} has been canceled",
        template_name: "#{event.detail}_event"
    end
  end

  def cancel_request_event(event)
    @event = event
    notification "#{@event.user.name} has canceled their request for #{@event.book}"
  end
end
