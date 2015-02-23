require 'csv'

namespace :csv_scenarios do
  desc "Creates new scenarios from slider settings csv files"
  task load: :environment do

    puts 'This will create new scenarios blah blah blah'

    Dir.glob("#{ Rails.root }/db/csv/*.csv") do |csv_file|

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



#    # add in logic for checking if scenario already exists so no overwrites
#
#    # Place any CSV files to be read in the db directory
#    file_path = "#{ Rails.root }/db/#{ENV['FILE_PATH']}"
#
#    CSV.foreach("#{ file_path }", converters: :all) do |row|
#      puts "Author: #{ row[1] }" if row[0] == 'Author'
#      puts "Titles: #{ row[1] }" if row[0] == 'Title'
#      puts "End Year: #{ row[1] }" if row[0] == 'End Year'
#
#      puts "#{ row[0] }: #{ row[1] }"
#      # set file path to argument when calling rake task
#      # if no file selected, prompt to add file as argument
#      # filepath = *arg
#
#      # state 'this will add new scenerios to the database from csv
#      # Are you sure you want to continue? (y/N)
#      # answer = STDIN.gets.chomp
#      # exit unless answer.downcase == 'y'
#
#      # calculate how many scenarios and for each do:
#      # title: the title provided (reformat csv)
#      # author: the author provided (reformat csv)
#      #   year.each: the year provided
#      #     key: key, value: value
#      # the rest will be default
#      # write method that fills the value if there's something there (else nil?)
#    end
#  end
#end
#
# Example request parameters:
#
# {
#   scenario: {
#     user_values: {
#       123: 1.34
#     }
#   },
