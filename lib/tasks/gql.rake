require 'open-uri'

namespace :gql do
  task :future => :environment do
    gql.future.rubel.pry
  end

  task :present => :environment do
    gql.present.rubel.pry
  end

  def gql
    Rails.cache.clear

    if settings = load_settings
      puts "** Using settings defined in #{json_file}"
      puts "** #{settings['settings']}"
      scenario = ApiScenario.new(settings['settings'])
    else
      puts "** Using default scenario"
      scenario = ApiScenario.default
    end

    scenario.gql(prepare: true).tap{|gql| gql.sandbox_mode = :console}
  end

  def load_settings
    json_file = ENV['JSON'] || "gqlconsole/default.json"
    settings = JSON.parse(open(json_file).read) rescue nil
    settings and settings['settings']
  end
end