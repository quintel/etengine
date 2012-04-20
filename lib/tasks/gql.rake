require 'open-uri'

namespace :g do
  task :f do Rake::Task["gql:future"].invoke; end
  task :p do Rake::Task["gql:present"].invoke; end
end

namespace :gql do

  task :future => :environment do
    init_environment
    gql.future.rubel.console
  end

  task :present => :environment do
    init_environment
    gql.present.rubel.console
  end

  task :dataset => :environment do
    gql = unprepared_gql
    hsh = Etsource::Loader.instance.raw_hash(gql.scenario.area_code)
    puts YAML::dump(hsh)
  end

  def init_environment
    GC.disable
    # Use etsource git repository per default
    # Use different directory by passing ETSOURCE_DIR=...
    unless ENV['ETSOURCE_DIR']
      Etsource::Base.loader(ETSOURCE_DIR)
    end

    puts "** Using: #{Etsource::Base.instance.export_dir}"
  end

  def gql
    gql = unprepared_gql
    gql.prepare
    gql.sandbox_mode = :console
    gql
  end

  # Loads the gql.
  def unprepared_gql
    Rails.cache.clear

    if settings = load_settings
      settings = settings[:settings].with_indifferent_access
      scenario = ApiScenario.new(ApiScenario.new_attributes(settings))
    else
      scenario = ApiScenario.default
    end

    gql = scenario.gql(prepare: false)
    gql.prepare
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