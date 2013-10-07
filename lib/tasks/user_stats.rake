require 'terminal-table'

IP_BLACK_LIST = ["127.0.0.1"]

def median(array)
  sorted = array.sort
  len = sorted.length
  return (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
end

def plot_table(title, headings, rows)
  table = Terminal::Table.new title: title, headings: headings, rows: rows
  a = Range.new(1,headings.size - 1).to_a.each { |i| table.align_column(i,:right) }
  puts table
end

def save_as_csv(path, key, postfix, data)
  CSV.open("#{ path }/#{ key }_#{ postfix }.csv", "wb") do |csv|
    csv << ["#{ key } - #{ postfix.humanize }"]
    data.each do |row|
      csv << row
    end
  end
end

desc <<-DESC
  Displays # of scenarios created over last x months (periods = x, default = 1).

  OPTIONS:

  summary=true      : Adds summary to the end of the overview.
  summary=only      : Monthly overviews are suppressed and only a summary is 
                      presented.
  csv=true          : Export overview to csv file as well; seperate files for 
                      scenarios and saved scenarios per source. Requires path
                      option (see below).
  csv=only          : No output to terminal, export to csv files only. Requires
                      path option (see below).
  path=<path>       : Path to directory where csv files are to be saved. 
                      Directory has to exist for task to execute.

  EXAMPLES:

  rake user_stats periods=3 summary=true

  > Outputs overview of user statistics for last 3 months, including a summary, 
    to the terminal.

  rake user_stats periods=3 summary=true csv=true path=user_statics/

  > Outputs overview of user statistics for last 3 months, including a summary, 
    to the terminal and creates a number of csv files in the directory 
    user_statistics/ (relative to the current directory).
DESC
task :user_stats => [:environment] do
  number_of_periods = ENV['periods'] || 1
  summary           = ENV['summary'] && (ENV['summary'].upcase == 'TRUE' || ENV['summary'].upcase == 'ONLY') || false
  summary_only      = ENV['summary'] && ENV['summary'].upcase == 'ONLY' || false
  csv               = ENV['csv'] && (ENV['csv'].upcase == 'TRUE' || ENV['csv'].upcase == 'ONLY') || false
  csv_only          = (ENV['csv'] && ENV['csv'].upcase == 'ONLY') || false
  path              = ENV['path'] || Dir.home
  
  if csv or csv_only
    unless File.directory?(path)
      puts "Please make sure you provide a valid path"
      exit
    end
  end
  
  periods = Range.new(1,number_of_periods.to_i).to_a

  scenario_summary_rows = {}
  saved_scenario_summary_rows = {}

  periods.each do |period|
    start_date = Date.today.beginning_of_month.months_ago(periods.size - period)
    end_date    = Date.today.end_of_month.months_ago(periods.size - period)

    scenarios = Scenario.where("created_at >= ? AND created_at <= ?", start_date, end_date)

    # Let's exclude any 'Mechanical Turk' created scenarios
    scenarios = scenarios.where("source != 'Mechanical Turk'")

    # TODO: filter out any QI-originated usage by figuring out the related IP address(es)
    scenarios.delete_if { |s| IP_BLACK_LIST.include?(s.remote_ip) }

    # Currently etflex doesn't register
    # https://github.com/quintel/etflex/issues/377
    scenarios.each { |s| s.source = "ETFlex" if s.source.nil? }
    scenarios.each { |s| s.source = "ETM - presets" unless s.preset_scenario_id.nil? }

    rows = []
    scenarios.group_by(&:source).each do |key, coll|
      count =  coll.size
      slider_counts = coll.map(&:user_values).map(&:size)
      avg = slider_counts.reduce(:+) / count.to_f.round
      rows << ["#{ key }",count,avg,median(slider_counts),  \
        slider_counts.min,slider_counts.max]
      scenario_summary_rows[key] ||= []
      scenario_summary_rows[key] << ["#{ start_date } - #{ end_date }",count,  \
        avg,median(slider_counts),slider_counts.min,slider_counts.max]
    end

    headings = []
    headings << "Source"
    headings << {value: "# of\nscenarios", alignment: :center}
    headings << {value: "Avg. # of\nsliders", alignment: :center}
    headings << {value: "Median # of\nsliders", alignment: :center}
    headings << {value: "Min. # of\nsliders", alignment: :center}
    headings << {value: "Max. # of\nsliders", alignment: :center}

    title = "User Statistics for period: #{ start_date } - #{ end_date }"

    plot_table(title, headings, rows) unless summary_only or csv_only

    rows = []
    scenarios.group_by(&:source).each do |key, coll|
      coll = coll.delete_if { |scen| scen.title == "API" }
      count =  coll.size
      slider_counts = coll.map(&:user_values).map(&:size)
      avg = coll.blank? ? 0 : slider_counts.reduce(:+) / count.to_f.round
      saved_scenario_summary_rows[key] ||= []
      if coll.blank?
        rows << ["#{ key }",0,"-","-","-","-"]
        saved_scenario_summary_rows[key] << ["#{ start_date } - #{ end_date }",  \
          0,"-","-","-","-"]
      else
        rows << ["#{ key }",count,avg,median(slider_counts),  \
          slider_counts.min,slider_counts.max]
        saved_scenario_summary_rows[key] << ["#{ start_date } - #{ end_date }",  \
          count,avg,median(slider_counts),slider_counts.min,slider_counts.max]
      end
    end

    headings[1] = {value: "# of saved\nscenarios", alignment: :center}

    plot_table(title, headings, rows) unless summary_only or csv_only
  end
  
  if summary or csv
    headings = []
    headings << "Period"
    headings << {value: "# of\nscenarios", alignment: :center}
    headings << {value: "Avg. # of\nsliders", alignment: :center}
    headings << {value: "Median # of\nsliders", alignment: :center}
    headings << {value: "Min. # of\nsliders", alignment: :center}
    headings << {value: "Max. # of\nsliders", alignment: :center}
    
    scenario_summary_rows.keys.each do |key|
      title = "Summary for #{ key }"
      postfix = "scenarios"
      plot_table(title, headings, scenario_summary_rows[key]) unless csv_only
      save_as_csv(path,key,postfix,scenario_summary_rows[key]) if csv
    end
    
    saved_scenario_summary_rows.keys.each do |key|
      title = "Summary for #{ key }"
      postfix = "saved_scenarios"
      headings[1] = {value: "# of saved\nscenarios", alignment: :center}
      plot_table(title, headings, saved_scenario_summary_rows[key]) unless csv_only
      save_as_csv(path,key,postfix,saved_scenario_summary_rows[key]) if csv
    end
  end
end

