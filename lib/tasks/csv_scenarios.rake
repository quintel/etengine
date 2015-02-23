require 'csv'

namespace :csv_scenarios do
  desc "Creates new scenarios from csv files containing user settings"
  task load: :environment do

    Dir.glob("#{ Rails.root }/db/csv/*.csv") do |csv_file|

      puts 'This will add new scenarios to the database'
      puts 'Are you sure you want to continue? (y/N)'

      answer = STDIN.gets.chomp
      exit unless answer.downcase == 'y'

      file_name = File.basename(csv_file, '.csv').split("_")

      author_name = "#{ file_name[2].capitalize } #{ file_name[3].capitalize }"
      title_name = "#{ file_name[0].capitalize }_#{ file_name[1] }"

      user_edits = Hash.new
      CSV.foreach(csv_file, converters: :all) do |row|
        user_edits[row[0]] = row[1].to_f
      end

      puts "Scenario #{ title_name } by #{ author_name } created."

      scenario = Scenario.create(author: author_name,
                                 title: title_name,
                                 end_year: file_name[1].to_i,
                                 area_code: 'nl',
                                 use_fce: false,
                                 user_values: user_edits
                                )

      puts "Scenario #{ title_name } by #{ author_name } successfully saved!" 
    end
    puts "All scenarios successfully saved - good job!" 
  end
end
