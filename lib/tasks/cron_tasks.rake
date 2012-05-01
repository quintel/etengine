task :clean_expired_api_scenarios => :environment do
  count = Scenario.expired.count
  all = Scenario.count
  Scenario.expired.delete_all
  puts "#{count} (total: #{all}) expired api_scenarios deleted"
end

task :clean_empty_scenarios => :environment do
  deletable = Scenario.deletable
  puts "Deleting #{deletable.count} scenarios"
  deletable.delete_all
end
