desc 'Generates list of users who have to be notified of CHP update'
task :chp_filter => [:environment] do
  key     = ENV['key']
  exclude = ENV['exclude'] || ''
  date    = ENV['date'] || "01/01/2009"
  email   = ENV['email'] && ENV['email'].upcase=='TRUE'
  file    = ENV['file']

  unless key && !key.blank?
    puts 'Missing key'
    exit
  end

  scenarios = Scenario.where('user_id >= ? AND updated_at >= ?',0,DateTime.parse(date)).all
  valid_scenarios = scenarios.select { |scen| scen.user_values.is_a?(Hash) }
  selection = valid_scenarios.select { |scen| scen.user_values.keys.delete_if { |h_key| not(exclude.blank?) ? Regexp.new(exclude).match(h_key.to_s) : false }.select { |h_key| Regexp.new(key).match(h_key.to_s)}.count > 0 }
  users = selection.collect { |scen| scen.user_id }.uniq
  active_users = users.select { |user| User.exists?(user) }
  
  puts "Selected scenarios  : #{selection.count}"
  puts "# of users affected : #{active_users.count}"
  
  if email && active_users.count > 0
    unless file
      puts 'Missing file'
      exit
    end
    
    unless File.exist?(File.dirname(file))
      puts 'Invalid path'
      exit
    end
    
    mail_addresses = active_users.collect { |id| User.find(id).email }
    
    File.open(file,'w') do |f|
      f.puts "Key: #{key}, exclude: #{exclude.blank? ? 'none' : exclude}, date: #{date}"
      mail_addresses.each { |address| f.print "#{address}"; unless address == mail_addresses.last; f.print ", "; end }
    end
  end
end