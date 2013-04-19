# Mailer for sending Reminders.
class ReminderMailer < ApplicationMailer
  include MoneyRails::ActionViewExtension

  def self.send_to_target(method, reminder)
    return if !reminder.can_send?
    mail = super
    reminder.subject = mail.subject
    reminder.save!
    mail
  end

  def reminder_mail(subject)
    mail_to_user @user, subject: subject
  end

  #--
  # Reminder types
  #++

  def fulfill_pledge(reminder)
    @user = reminder.user
    @pledge = reminder.pledge
    @request_count = Request.not_granted.count
    reminder_mail "Fulfill your pledge of #{@pledge.quantity} Objectivist books"
  end

  def fulfill_donations(reminder)
    @user = reminder.user
    @outstanding_count = Donation.needs_fulfillment.count
    @fulfillment_count = @user.fulfillments.where('created_at > ?', 1.week.ago).count
    @single = @outstanding_count == 1
    subject = @single ? "1 book is" : "#{@outstanding_count} books are"
    reminder_mail "#{subject} waiting to be fulfilled on Free Objectivist Books"
  end

  def renew_request(reminder)
    @user = reminder.user
    @request = reminder.request
    @use_autocancel_at = Time.until(@request.autocancel_at) > 3.days
    @mention_donor_drive = Time.now < Time.parse("2013-04-10")  # limited-time postscript
    reminder_mail "Do you still want #{@request.book}?"
  end

  def send_books(reminder)
    @user = reminder.user
    @donations = reminder.donations
    @donation = @donations.first

    @eligible = @donations.select &:can_send_money?
    @eligible_total = @eligible.map(&:price).sum
    @all_eligible = @eligible.size == @donations.size

    @single = @donations.size == 1
    subject = if @single
      "Have you sent #{@donation.book} to #{@donation.student.name} yet?"
    else
      "Have you sent your #{@donations.size} Objectivist books to students yet?"
    end
    reminder_mail subject
  end

  def confirm_receipt_unsent(reminder)
    @user = reminder.user
    @donation = reminder.donation
    @granted_at = @donation.created_at
    reminder_mail "Have you received #{@donation.book} yet?"
  end

  def confirm_receipt(reminder)
    @user = reminder.user
    @donation = reminder.donation
    reminder_mail "Have you received #{@donation.book} yet?"
  end

  def read_books(reminder)
    @user = reminder.user
    @donation = reminder.donation
    @received_at = @donation.received_at
    reminder_mail "Have you finished reading #{@donation.book}?"
  end
end
