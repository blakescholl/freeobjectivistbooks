# Sends reminders, typically as a delayed job.
#
# The schedule_reminders method is invoked via 'rake reminders:schedule', which is run by Heroku once a day.
#
# This class exists to work around https://github.com/collectiveidea/delayed_job/issues/306
class ReminderJob

  # All the Reminder types we send.
  TYPES = [
    Reminders::FulfillPledge,
    Reminders::RenewRequest,
    Reminders::SendBooks,
    Reminders::SendMoney,
    Reminders::ConfirmReceiptUnsent,
    Reminders::ConfirmReceipt,
    Reminders::ReadBooks,
  ]

  # Sends all reminders, inline. (Rarely used in production.)
  def self.send_all_reminders
    new.send_all_reminders
  end

  # Schedules a Delayed::Job to send all reminders offline.
  def self.schedule_reminders
    Delayed::Job.enqueue new
  end

  def logger
    @logger ||= Rails.logger
  end
  private :logger

  # Sends all reminders of the given Reminder subclass.
  def send_reminders(type)
    method = type.type_name

    logger.info "Gathering #{method} reminders..."
    reminders = type.all_reminders

    logger.info "Filtering #{reminders.size} #{method} reminders..."
    reminders.select! {|reminder| reminder.can_send?}

    if reminders.any?
      logger.info "Sending #{reminders.size} #{method} reminders..."
      ReminderMailer.send_campaign method, reminders
      logger.info "Done with #{method} reminders"
    else
      logger.info "No #{method} reminders to send"
    end

    reminders
  end

  # Sends all reminders.
  def send_all_reminders
    logger.info "Sending all reminders..."
    reminders = TYPES.inject([]) {|reminders,type| reminders += send_reminders type}
    logger.info "All reminders sent"
    reminders
  end

  # Performs reminder sending (invoked by the Delayed::Job subsystem).
  def perform
    send_all_reminders
  end
end
