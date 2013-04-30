namespace :autocancel do
  desc "Schedule autocancel of requests to be run by a worker thread"
  task :schedule => :environment do
    AutocancelJob.schedule
  end
end

namespace :reminders do
  desc "Schedule reminders to be sent by a worker thread"
  task :schedule => :environment do
    ReminderJob.schedule_reminders
  end
end

namespace :pledge_monitor do
  desc "Schedule pledge monitor to turn over pledges whose time is up"
  task :schedule => :environment do
    PledgeMonitor.schedule
  end
end

namespace :price_checker do
  desc "Schedule price checker to update prices on all eligible books"
  task :schedule => :environment do
    PriceChecker.schedule
  end
end
