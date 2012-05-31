require 'spec_helper'

describe "Etsource" do
  def self.initialize_etsource(path)
    etsource = Etsource::Base.instance

    etsource.base_dir       = path
    etsource.cache_dataset  = false
    etsource.cache_topology = false
  end

  # Find all the folders that contain a tests folder.
  Dir.glob("#{Etsource::Base.instance.export_dir}/tests/".gsub('//', '/')).each do |tests_dir|
    base_dir = tests_dir.gsub(/\/tests\/$/, '')
    initialize_etsource(base_dir)

    # iterate over every test suite yml file within tests
    Dir.glob(base_dir + "/tests/*.yml").each do |test_suite|
      suite = YAML::load(File.read(test_suite))

      # -- Finally the context, before and it's --------------------------------

      context test_suite.gsub(ETSOURCE_DIR, '') do
        describe do
          before(:all) do
            @scenario = Scenario.default(suite.fetch('settings', {}))
            @scenario.build_update_statements
            @gql = @scenario.gql(prepare: true)
          end

          suite['tests'].each do |key, hsh|

            it "#{key}" do
              result = @gql.query(hsh['query'])
              result.present_value.should be_within_a_percent(hsh['present']) if hsh['present']
              result.future_value.should  be_within_a_percent(hsh['future'])  if hsh['future']
            end

          end# suite

        end
      end# context
    end# Dir.glob
  end# Dir.glob
end

