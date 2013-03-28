namespace :autocancel do
  desc "Schedule autocancel of requests to be run by a worker thread"
  task :schedule => :environment do
    AutocancelJob.schedule
  end
end
