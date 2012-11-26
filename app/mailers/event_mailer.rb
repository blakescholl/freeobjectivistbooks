class EventMailer < ApplicationMailer
  def self.mail_for_event(event, role)
    self.send "#{event.type}_event", event, role
  end

  def notification(role, subject, options = {})
    @recipient = @event.send role
    template = options[:template] || "#{@event.type}_event"
    mail_to_user @recipient, subject: subject, template_name: "#{role}/#{template}"
  end

  def grant_event(event, role)
    @event = event
    @closer = "Happy reading"
    notification role, "We found a donor to send you #{@event.book}!"
  end

  def update_event(event, role)
    @event = event
    notification role, "#{@event.user.name} #{@event.detail} for #{@event.book}"
  end

  def flag_event(event, role)
    @event = event
    notification role, "Problem with your shipping info for #{@event.book}"
  end

  def fix_event(event, role)
    @event = event
    action = event.detail || "responded to your flag"
    notification role, "#{@event.user.name} #{action} for #{@event.book}"
  end

  def message_event(event, role)
    @event = event
    message_type = event.is_thanks? ? "thank-you note for #{@event.book}" : "message about #{@event.book}"
    notification role, "#{@event.user.name} sent you a #{message_type}"
  end

  def update_status_event(event, role)
    @event = event
    @review = event.donation.review
    @closer = "Happy reading" if event.to_student? && event.donation.sent?
    notification role, "#{@event.user.name} has #{@event.detail} #{@event.book}", template: "#{@event.detail}_event"
  end

  def cancel_donation_event(event, role)
    @event = event
    @closer = "Yours"
    case @event.to
    when @event.student
      notification role, "We need to find you a new donor for #{@event.book}"
    when @event.donor
      notification role, "Your donation of #{@event.book} to #{@event.student.name} has been canceled",
        template: "#{event.detail}_event"
    end
  end

  def cancel_request_event(event, role)
    @event = event
    notification role, "#{@event.user.name} has canceled their request for #{@event.book}"
  end
end
