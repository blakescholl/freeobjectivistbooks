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

  def send_books(reminder)
    @user = reminder.user
    @donations = reminder.donations
    @donation = @donations.first
    @single = @donations.size == 1
    subject = if @single
      "Have you sent #{@donation.book} to #{@donation.student.name} yet?"
    else
      "Have you sent your #{@donations.size} Objectivist books to students yet?"
    end
    reminder_mail subject
  end

  def send_money(reminder)
    @user = reminder.user
    @donations = reminder.donations
    @donation = @donations.first
    @single = @donations.size == 1
    @total = @donations.map {|d| d.price}.sum
    reminder_mail "Please send a contribution of #{humanized_money_with_symbol @total} for your donations on Free Objectivist Books"
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
