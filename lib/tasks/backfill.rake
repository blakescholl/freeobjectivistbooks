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

  task :flags => :environment do
    count = 0
    offset = ENV['OFFSET'].to_i if ENV['OFFSET']
    limit = ENV['LIMIT'].to_i if ENV['LIMIT']

    Donation.find_each do |donation|
      next if donation.flag_events.empty? && donation.fix_events.empty? && !donation.flagged_deprecated?

      count += 1
      next if offset && count <= offset
      break if limit && count > limit

      puts "Donation #{donation.id}: #{donation.donor} gave #{donation.book} to #{donation.student} (request #{donation.request.id})"

      flag = nil

      donation.events.each do |event|
        case event.type
        when "flag"
          puts "  Flag event #{event.id} at #{event.happened_at} by #{event.user}"
          if event.flag
            flag = event.flag
            puts "    already has flag #{flag.id}, skipping"
            puts "    ERROR: flag user #{flag.user} is not event user #{event.user}" if flag.user != event.user
            puts "    ERROR: flag type is #{flag.type}" if flag.type != 'shipping_info'
          else
            flag = donation.flags.create user: event.user, type: 'shipping_info', message: event.message
            puts "    created flag #{flag.id}"
            flag.events << event
          end
        when "fix", "update"
          next if event.type == "update" && flag.nil?
          puts "  #{event.type.capitalize} event #{event.id} at #{event.happened_at} by #{event.user} #{event.detail}"
          if event.flag
            flag = event.flag
            puts "    already has flag #{flag.id}; skipping"
            puts "    ERROR: flag is not fixed" if !flag.fixed?
          else
            if flag.nil?
              flag = donation.flags.create type: 'missing_address'
              puts "    no flag event; assuming missing address; created flag #{flag.id}"
              puts "    ERROR: event detail is '#{event.detail}'" if event.detail != "added a shipping address"
            else
              puts "    adding to flag #{flag.id}, fixing"
            end
            flag.fixed = true
            flag.fix_type = event.detail
            flag.fix_message = event.message
            flag.save!
            flag.events << event
          end
        end
      end

      if donation.flagged_deprecated?
        puts "  Donation flagged"
        if flag.nil?
          if donation.address.blank? || donation.canceled?
            flag = donation.flags.create type: 'missing_address'
            puts "    no flag event; assuming missing address; created flag #{flag.id}"
          else
            puts "    ERROR: active donation with address flagged, but no flag event!"
          end
        else
          puts "    active flag is #{flag.id} #{flag.type} #{flag.user}"
        end

        if flag
          puts "    ERROR: donation flagged, but flag is fixed!" if flag.fixed?
          donation.flag = flag
          donation.save!(validate: false)
        end
      else
        puts "  Donation not flagged"
        if donation.sent?
          puts "    status is #{donation.status}"
        elsif donation.canceled?
          puts "    donation is canceled"
        else
          puts "    ERROR: current, active flag #{flag.id} on active, unsent donation" if flag && !flag.fixed?
        end
      end
    end

    puts "DONE, processed #{count} donations"
  end
end
