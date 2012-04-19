require 'open-uri'

namespace :gql do
  task :future => :environment do
    rubel = gql.future.rubel
    rubel.enable_code_completion
    rubel.pry
  end

  task :present => :environment do
    rubel = gql.present.rubel
    rubel.enable_code_completion
    rubel.pry
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

    gql = scenario.gql(prepare: true)
    gql.sandbox_mode = :console
    gql
  end

  def load_settings
    json_file = ENV['JSON'] || "gqlconsole/default.json"
    settings = JSON.parse(open(json_file).read) rescue nil
    settings and settings['settings']
  end
end