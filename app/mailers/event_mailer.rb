class EventMailer < ApplicationMailer
  TEMPLATE_PATH = Rails.root.join('app', 'views', mailer_name)

  def self.mail_for_event(event, recipient)
    self.send "#{event.type}_event", event, recipient
  end

  def template_name_for(role, template_basename)
    path = TEMPLATE_PATH.join(role.to_s, "#{template_basename}.*")
    Dir.glob(path).any? ? "#{role}/#{template_basename}" : template_basename
  end

  def format_recipients(event, recipient)
    all_recipients = event.recipients
    names = all_recipients.map {|user| user == recipient ? "you" : user.name}
    names.to_sentence
  end

  def notification(recipient, subject, options = {})
    @recipient = recipient
    role = @event.role_for recipient
    template_basename = options[:template_basename] || "#{@event.type}_event"
    template_name = template_name_for role, template_basename
    mail_to_user @recipient, subject: subject, template_name: template_name
  end

  def grant_event(event, recipient)
    @event = event
    @closer = "Happy reading"
    notification recipient, "We found a donor to send you #{@event.book}!"
  end

  def update_event(event, recipient)
    @event = event
    notification recipient, "#{@event.user.name} #{@event.detail} for #{@event.book}"
  end

  def flag_event(event, recipient)
    @event = event
    subject = case @event.role_for(recipient)
    when :student then "Problem with your shipping info for #{@event.book}"
    when :donor then "Delay in sending #{@event.book} to #{@event.student}"
    end
    notification recipient, subject
  end

  def fix_event(event, recipient)
    @event = event
    action = event.detail || "responded to your flag"
    notification recipient, "#{@event.user.name} #{action} for #{@event.book}"
  end

  def message_event(event, recipient)
    @event = event
    @recipient_list = format_recipients event, recipient
    message_type = event.is_thanks? ? "thank-you note for #{@event.book}" : "message about #{@event.book}"
    notification recipient, "#{@event.user.name} sent #{@recipient_list} a #{message_type}"
  end

  def update_status_event(event, recipient)
    @event = event
    @role = event.role_for recipient
    @review = event.donation.review

    if @event.detail == "sent"
      subject = "#{@event.book} is on its way"
      if @role == :student
        @closer = "Happy reading"
      else
        subject += " to #{@event.student}"
      end
    else
      subject = "#{@event.user} has #{@event.detail} #{@event.book}"
    end

    notification recipient, subject, template_basename: "#{@event.detail}_event"
  end

  def cancel_donation_event(event, recipient)
    @event = event
    @closer = "Yours"
    case @event.role_for(recipient)
    when :student
      notification recipient, "We need to find you a new donor for #{@event.book}"
    when :donor
      notification recipient, "Your donation of #{@event.book} to #{@event.student.name} has been canceled",
        template_basename: "#{event.detail}_event"
    end
  end

  def cancel_request_event(event, recipient)
    @event = event
    notification recipient, "#{@event.user.name} has canceled their request for #{@event.book}"
  end

  def autocancel_event(event, recipient)
    @event = event
    @mention_donor_drive = Time.now < Time.parse("2013-04-10")  # limited-time postscript
    notification recipient, "We've canceled your request for #{@event.book}"
  end
end
