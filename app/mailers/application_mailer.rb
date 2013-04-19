class ApplicationMailer < ActionMailer::Base
  default from: "Ayn Rand and Objectivist Books For Students <jason@rationalegoist.com>"

  # Important for avoiding Gmail spam filters, as per
  # http://blog.mailgun.net/post/tips-tricks-avoiding-gmail-spam-filtering-when-using-ruby-on-rails-action-mailer/
  default "Message-ID" => lambda {"#{SecureRandom.uuid}@#{Rails.application.config.mailgun_domain}"}

  def mail_to_user(user, options)
    options = if Rails.application.config.email_recipient_override
      options.merge(
        to: Rails.application.config.email_recipient_override,
        subject: "#{options[:subject]} (recipient was: #{user.email})",
      )
    else
      options.merge(to: user.email)
    end

    mail options
  end

  def self.campaign_for_method(method)
    type = name.sub(/Mailer\Z/,"").titleize.downcase
    name = "#{method.to_s.humanize} #{type} #{Date.today.strftime "%Y-%m-%d"}"
    id = name.gsub(/\s+/, "_").gsub(/[^\w-]/, "").downcase
    Mailgun::Campaign.find_or_create id: id, name: name
  end

  def self.send_to_target(method, target)
    mail = send method, target
    Rails.logger.info "sending: #{mail.to} <= \"#{mail.subject}\""
    mail.deliver
    mail
  end

  def self.send_campaign(method, targets)
    campaign = campaign_for_method method
    default 'X-Mailgun-Campaign-ID' => campaign.id
    Rails.logger.info "Beginning campaign: #{campaign.name}"
    targets.each {|target| send_to_target method, target}
  end
end
