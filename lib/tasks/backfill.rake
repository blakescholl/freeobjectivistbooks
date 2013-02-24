namespace :backfill do
  task :user_locations => :environment do
    User.find_each do |user|
      user.location_name = user.location_deprecated
      user.save!(validate: false)
    end
  end
end
