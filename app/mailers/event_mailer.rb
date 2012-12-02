class EventMailer < ApplicationMailer
  helper :event_mailer

  TEMPLATE_PATH = Rails.root.join('app', 'views', mailer_name)

  def self.mail_for_event(event, role)
    self.send "#{event.type}_event", event, role
  end

  def template_name_for(role, template_basename)
    path = TEMPLATE_PATH.join(role.to_s, "#{template_basename}.*")
    Dir.glob(path).any? ? "#{role}/#{template_basename}" : template_basename
  end

  def notification(role, subject, options = {})
    @recipient = @event.send role
    template_basename = options[:template_basename] || "#{@event.type}_event"
    template_name = template_name_for role, template_basename
    mail_to_user @recipient, subject: subject, template_name: template_name
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
    @flagger_role = case event.user
    when event.donor then :donor
    when event.fulfiller then :fulfiller
    end
    subject = case role
    when :student then "Problem with your shipping info for #{@event.book}"
    when :donor then "Delay in sending #{@event.book} to #{@event.student}"
    end
    notification role, subject
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
    @role = role
    @review = event.donation.review

    if @event.detail == "sent"
      subject = "#{@event.book} is on its way"
      if role == :student
        @closer = "Happy reading"
      else
        subject += " to #{@event.student}"
      end
    else
      subject = "#{@event.user} has #{@event.detail} #{@event.book}"
    end

    notification role, subject, template_basename: "#{@event.detail}_event"
  end

  def cancel_donation_event(event, role)
    @event = event
    @closer = "Yours"
    case @event.to
    when @event.student
      notification role, "We need to find you a new donor for #{@event.book}"
    when @event.donor
      notification role, "Your donation of #{@event.book} to #{@event.student.name} has been canceled",
        template_basename: "#{event.detail}_event"
    end
  end

  def cancel_request_event(event, role)
    @event = event
    notification role, "#{@event.user.name} has canceled their request for #{@event.book}"
  end
end
