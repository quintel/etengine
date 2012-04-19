require 'open-uri'

namespace :g do
  task :f do Rake::Task["gql:future"].invoke; end
  task :p do Rake::Task["gql:present"].invoke; end
end

namespace :gql do
  task :future => :environment do
    console(gql.future.rubel)
  end

  task :present => :environment do
    console(gql.present.rubel)
  end

  def console(rubel)
    rubel.enable_code_completion
    Pry.start(rubel, prompt: [proc { "GQL: " }])
  end

  def gql
    Rails.cache.clear

    if settings = load_settings
      settings = settings[:settings].with_indifferent_access
      scenario = ApiScenario.new(ApiScenario.new_attributes(settings))
    else
      scenario = ApiScenario.default
    end

    gql = scenario.gql(prepare: true)
    gql.sandbox_mode = :console
    gql
  end

  def load_settings
    json_file = ENV['JSON'] || "gqlconsole/default.json"
    settings = JSON.parse(open(json_file).read) rescue nil
    if settings
      puts "** Using settings defined in #{json_file}"
      puts "** #{settings['settings']}"
      settings and settings.with_indifferent_access
    else
      puts "** Using default scenario"
      nil
    end  
  end
end