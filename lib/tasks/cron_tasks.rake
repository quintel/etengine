task :clean_expired_api_scenarios => :environment do
  count = Scenario.expired.count
  all = Scenario.count
  Scenario.expired.delete_all
  puts "#{count} (total: #{all}) expired api_scenarios deleted"
end
