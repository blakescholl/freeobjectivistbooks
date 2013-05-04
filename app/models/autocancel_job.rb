# Auto-cancels old requests that haven't been renewed recently, typically as a delayed job.
#
# The schedule_autocancel method is invoked via 'rake autocancel:schedule', which will be run by Heroku once a day.
class AutocancelJob
  # Autocancel the given requests, if eligible and not already canceled.
  def autocancel(requests)
    requests = requests.reject {|request| request.canceled?}
    requests.inject([]) do |canceled,request|
      request.autocancel_if_needed!
      if request.canceled?
        Rails.logger.info "Autocanceled #{request.student}'s request for #{request.book} (open since #{request.open_at.to_date})"
        canceled << request
      end
      canceled
    end
  end

  # Performs autocancel on all eligible requests (invoked by the Delayed::Job subsystem).
  def perform
    canceled = []
    canceled += autocancel Request.open_too_long
    canceled += autocancel Request.flagged_too_long
    canceled
  end

  # Schedules a Delayed::Job to send all reminders offline.
  def self.schedule
    Delayed::Job.enqueue new
  end
end
