namespace :backfill do
  task :user_locations => :environment do
    User.find_each do |user|
      user.location_name = user.location_deprecated
      user.save!(validate: false)
    end
  end

  task :donation_pledges => :environment do
    Donation.find_each do |donation|
      donation.pledge = donation.user.current_pledge
      donation.save!
    end
  end
end
