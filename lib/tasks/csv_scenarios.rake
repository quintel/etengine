namespace :csv_scenarios do
  desc "Creates new scenarios from slider settings csv files"
  task :load do

    Dir.glob("#{ Rails.root }/db/csv/*.csv") do |csv_file|
      scenario = Scenario.create
      # create the scenario and fill the metadata
        CSV.foreach(csv_file, converters: :all) do |row|
          # read in key/value pairs
      end
    end
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
