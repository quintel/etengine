require 'terminal-table'

def median(array)
  sorted = array.sort
  len = sorted.length
  return (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
end

desc 'Displays number of created scenarios during the last week.'
task :user_stats => [:environment] do
  number_of_days = ENV['period'].to_i || 7

  # TODO: let's not query for mechanical turk origin scenarios.
  scenarios = Scenario.where("created_at >= ?", Date.today - number_of_days.days)

  # Currently etflex doesn't register
  # https://github.com/quintel/etflex/issues/377
  scenarios.each { |s| s.source = "ETFlex" if s.source.nil? }
  scenarios.each { |s| s.source = "ETM - presets" unless s.preset_scenario_id.nil? }

  rows = []
  scenarios.group_by(&:source).each do |key, coll|
  # => { etmodel: [<Scenarios>,..], mixer: ...etc }
    
    count =  coll.size
    slider_counts = coll.map(&:user_values).map(&:size)
    avg = slider_counts.reduce(:+) / count.to_f.round
    rows << ["#{ key }",count,avg,median(slider_counts),slider_counts.min,slider_counts.max]
  end
  
  headings = []
  headings << "Source"
  headings << {:value => "# of\nscenarios", :alignment => :center}
  headings << {:value => "Avg. # of\nsliders", :alignment => :center}
  headings << {:value => "Median # of\nsliders", :alignment => :center}
  headings << {:value => "Min. # of\nsliders", :alignment => :center}
  headings << {:value => "Max. # of\nsliders", :alignment => :center}
  
  table = Terminal::Table.new :title => "User Statistics", :headings => headings, :rows => rows
  [1,2,3,4,5].each { |i| table.align_column(i,:right) }
  puts table
end

