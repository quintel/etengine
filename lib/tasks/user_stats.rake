desc 'Displays number of created scenarios during the last week.'
task :user_stats => [:environment] do
  number_of_days = ENV['period'].to_i || 7

  # TODO: let's not query for mechanical turk origin scenarios.
  scenarios = Scenario.where("created_at >= ?", Time.now - number_of_days.days)

  # Currently etflex doesn't register
  # https://github.com/quintel/etflex/issues/377
  scenarios.each { |s| s.source = "ETFlex" if s.source.nil? }
  scenarios.each { |s| s.source = "ETM - presets" unless s.preset_scenario_id.nil? }

  scenarios.group_by(&:source).each do |key, coll|
  # => { etmodel: [<Scenarios>,..], mixer: ...etc }

    print "#{ key }: "
    print "#{ coll.size } - "

    puts coll.map(&:user_values).map(&:size).reduce(:+) / coll.size.to_f.round

  end
end

