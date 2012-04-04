namespace :etsource do
  task :diff do
    require 'open-uri'
    params = ""
    params = "settings[scenario_id]=#{ENV['SCENARIO']}&" if ENV["SCENARIO"]
    if ENV["GQUERIES"]
      gqueries = Dir.glob("../etsource/gqueries/**/*.gql").
        select{|f| f.match ENV['GQUERIES'] }.
        map{|f| f.split('/').last.split('.').first}
      params += "r=#{CGI::escape gqueries.join(';')}&"
    end
    hsh  = {}
    
    apis = ['localhost:3000', 'beta.ete.io'].map do |u| 
      "http://#{u}/api/v2/api_scenarios/test.json"
    end

    hsh['name'] = %w[present future present future]
    apis.each do |api|
      json = JSON.parse(open(api+'?'+params).string)
      json['result'].each do |key, result|
        hsh[key] ||= []
        hsh[key] << result.map{|arr| arr.last.round(2)}
        hsh[key].flatten!
      end
    end
    
    puts hsh.to_table.to_s
  end

  def initialize_etsource(path)
    etsource = Etsource::Base.instance
    
    etsource.base_dir       = path
    etsource.cache_dataset  = false
    etsource.cache_topology = false
    etsource.import_current!
    etsource
  end

  task :debug => :environment do
    DEBUG_REPORT = true

    initialize_etsource(ENV['ETSOURCE_DIR'])
    scenario = ApiScenario.default.tap{|a| a.code = 'nl'}
    scenario.gql(prepare: true)
  end

  # Updates the files based on the settings defined in the .yml
  # If you want to create a new one, simply create a new file with the
  # settings you desire.
  desc 'Update files in tests/*.yml.'
  task :update_tests => :environment do
    selector = ENV['GQUERIES'] || "**/dashboard_*.gql"

    base_dir = Etsource::Base.instance.base_dir
    initialize_etsource(base_dir)

    puts "Updating: "
    Dir.glob(base_dir + "/tests/*.yml").each do |test_suite_file|
      puts "- #{test_suite_file}"

      suite    = YAML::load(File.read(test_suite_file))
      scenario = ApiScenario.default(suite.fetch('settings', {}))
      scenario.build_update_statements
      gql      = scenario.gql(prepare: true)

      tests = {}
      # Find all interesting gqueries. As of now only use the dashboard
      Dir.glob(base_dir+'/gqueries/'+selector).each do |f|
        query_name = f.split('/').last.split('.').first
        next if query_name.match(/^\d/) # hard-coded skip for gqueries that start with 1990
        gquery = "Q(#{query_name})" 
        result = gql.query(gquery)

        tests[query_name] = {
          'query'   => gquery,
          'present' => result.present_value,
          'future'  => result.future_value
        }
      end

      # Overwrite existing file
      File.open(test_suite_file, 'w') do |f|
        f << YAML::dump({ 
          'settings' => suite.fetch('settings', {}),
          'tests'    => tests
        })
      end
    end
  end

  namespace :gqueries do
    task :export => :environment do
      Etsource::Gqueries.new.export
    end

    task :import => :environment do
      Etsource::Gqueries.new.import!
    end
  end

  namespace :inputs do
    task :export => :environment do
      Etsource::Inputs.new.export
    end

    task :import => :environment do
      Etsource::Inputs.new.import!
    end
  end
end
