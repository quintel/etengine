require 'open-uri'

namespace :g do
  task :f do Rake::Task["gql:future"].invoke; end
  task :p do Rake::Task["gql:present"].invoke; end
end

namespace :gql do

  namespace :check do
    desc 'Check if inputs run.'
    task :inputs => :environment do
      init_environment
      exceptions = {}
      
      gql = unprepared_gql
      Input.all.each do |input|
        begin
          gql.update_graph(gql.future, input, 3.0)
        rescue => e
          exceptions[input] = e
        end
      end
      
      puts "=" * 20
      if exceptions.empty?
        puts "All inputs completed" 
      else
        exceptions.each do |input, e|
          puts "# #{input.key}"
          puts e.message
          puts "-" * 20
        end
        puts "=" * 20
        puts "Failed: #{exceptions.keys.map(&:key).join(', ')}"
      end
    end

    desc 'Check if gqueries run.'
    task :gqueries => :environment do
      init_environment
      exceptions = {}
      
      gql = prepared_gql
      Gquery.all.each do |gquery|
        begin
          gql.query(gquery)
        rescue => e
          exceptions[gquery] = e
        end
      end
      
      puts "=" * 20
      if exceptions.empty?
        puts "All inputs completed" 
      else
        exceptions.each do |gquery, e|
          puts "# #{gquery.key}"
          puts e.message
          puts "-" * 20
        end
        puts "=" * 20
        puts "Failed: #{exceptions.keys.map(&:key).join(', ')}"
      end
    end
  end

  task :future => :environment do
    init_environment
    gql.future.rubel.console
  end

  task :present => :environment do
    init_environment
    gql.present.rubel.console
  end

  task :debug => :environment do
    init_environment
    gql(:debug => true).future.rubel.console
  end

  task :performance => :environment do
    init_environment
    g = gql
    Gquery.all.each do |gquery|
      begin
        puts gquery.key
        g.query(gquery)
      rescue => e
        puts 'rescue'
        #binding.pry
      end
    end
  end

  task :dataset => :environment do
    gql = unprepared_gql
    hsh = Etsource::Loader.instance.raw_hash(gql.scenario.area_code)
    puts YAML::dump(hsh)
  end

  def init_environment
    GC.disable
    Rails.cache.clear
    # Use etsource git repository per default
    # Use different directory by passing ETSOURCE_DIR=...
    unless ENV['ETSOURCE_DIR']
      Etsource::Base.loader(ETSOURCE_DIR)
    end

    puts "** Using: #{Etsource::Base.instance.export_dir}"
  end

  def gql(options = {})
    gql = unprepared_gql
    gql.future.rubel.pry if options[:debug] == true
    gql.prepare
    gql.sandbox_mode = :console
    gql
  end
  alias prepared_gql gql

  # Loads the gql.
  def unprepared_gql
    Rails.cache.clear

    if settings = load_settings
      settings = settings[:settings].with_indifferent_access
      scenario = Scenario.new(Scenario.new_attributes(settings))
    else
      scenario = Scenario.default
    end

    gql = scenario.gql(prepare: false)
    gql.sandbox_mode = :console
    gql.init_datasets
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
