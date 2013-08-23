require 'terminal-table'

def median(array)
  sorted = array.sort
  len = sorted.length
  return (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
end

def plot_table(title, headings, rows)
  table = Terminal::Table.new :title => title, :headings => headings, :rows => rows
  a = *(1..headings.size - 1).each { |i| table.align_column(i,:right) }
  puts table
end

desc 'Displays number of created scenarios over the last x days (period=x, default = 7 days).'
task :user_stats => [:environment] do
  number_of_periods = ENV['periods'] || 1
  summary           = ENV['summary'] && (ENV['summary'].upcase=='TRUE' || ENV['summary'].upcase=='ONLY') || false
  summary_only      = ENV['summary'] && ENV['summary'].upcase=='ONLY' || false
  
  periods = *(1..number_of_periods.to_i)

  scenario_summary_rows = {}
  saved_scenario_summary_rows = {}

  periods.each do |period|
    start_date = Date.today.beginning_of_month.months_ago(periods.size - period)
    end_date    = Date.today.end_of_month.months_ago(periods.size - period)
    
    # TODO: let's not query for mechanical turk origin scenarios.
    scenarios = Scenario.where("created_at >= ? AND created_at <= ?", start_date, end_date)

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
      scenario_summary_rows[key] ||= []
      scenario_summary_rows[key] << ["#{start_date} - #{end_date}",count,avg,median(slider_counts),slider_counts.min,slider_counts.max]
    end

    headings = []
    headings << "Source"
    headings << {:value => "# of\nscenarios", :alignment => :center}
    headings << {:value => "Avg. # of\nsliders", :alignment => :center}
    headings << {:value => "Median # of\nsliders", :alignment => :center}
    headings << {:value => "Min. # of\nsliders", :alignment => :center}
    headings << {:value => "Max. # of\nsliders", :alignment => :center}

    title = "User Statistics for period: #{start_date} - #{end_date}"

    plot_table(title, headings, rows) unless summary_only

    rows = []
    scenarios.group_by(&:source).each do |key, coll|
    # => { etmodel: [<Scenarios>,..], mixer: ...etc }
      coll = coll.delete_if { |scen| scen.title == "API" }
      count =  coll.size
      slider_counts = coll.map(&:user_values).map(&:size)
      avg = coll.blank? ? 0 : slider_counts.reduce(:+) / count.to_f.round
      saved_scenario_summary_rows[key] ||= []
      if coll.blank?
        rows << ["#{ key }",0,"-","-","-","-"]
        saved_scenario_summary_rows[key] << ["#{start_date} - #{end_date}",0,"-","-","-","-"]
      else
        rows << ["#{ key }",count,avg,median(slider_counts),slider_counts.min,slider_counts.max]
        saved_scenario_summary_rows[key] << ["#{start_date} - #{end_date}",count,avg,median(slider_counts),slider_counts.min,slider_counts.max]
      end
    end

    headings[1] = {:value => "# of saved\nscenarios", :alignment => :center}

    plot_table(title, headings, rows) unless summary_only
  end
  
  if summary
    headings = []
    headings << "Period"
    headings << {:value => "# of\nscenarios", :alignment => :center}
    headings << {:value => "Avg. # of\nsliders", :alignment => :center}
    headings << {:value => "Median # of\nsliders", :alignment => :center}
    headings << {:value => "Min. # of\nsliders", :alignment => :center}
    headings << {:value => "Max. # of\nsliders", :alignment => :center}
    
    scenario_summary_rows.keys.each do |key|
      title = "Summary for #{key}"
      plot_table(title, headings, scenario_summary_rows[key])
    end
    
    saved_scenario_summary_rows.keys.each do |key|
      title = "Summary for #{key}"
      headings[1] = {:value => "# of saved\nscenarios", :alignment => :center}
      plot_table(title, headings, saved_scenario_summary_rows[key])
    end
  end
end

