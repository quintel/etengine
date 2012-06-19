# Mechanical Turk DSL
# 
# before(:all) do
#   load_scenario({end_year: 2030}) do
#     move_slider 3, 2.0
#   end
# end
#
# it "V(foo,demand)" do
#    the_present.should ...
#    the_future.should
#    the_relative_increase.should
#    the_absolute_increase.should
# end
#
module MechanicalTurk
  class SpecDSL

    ENDPOINTS = {
      'beta' => "http://beta.ete.io/api/v2/api_scenarios/test.json",
      'localhost' => "http://localhost:3000/api/v2/api_scenarios/test.json"
    }

    def initialize
      @gqueries = []
      @user_values_log = {}
      @_memo = {}
    end

    def print_comparison(api_endpoint = 'localhost', year = :future)
      json = RestClient.get(ENDPOINTS[api_endpoint] +"?"+api_params.to_query)

      arr = [['Future', 'Spec', api_endpoint]]
      JSON.parse(json)['result'].each do |key, result_set|
        arr << [key, the_future(key), result_set.last.last]   if year == :future
        arr << [key, the_present(key), result_set.first.last] if year == :present
      end

      arr.to_table(:first_row_is_head => true).to_s.tap{ |out| puts out }
    end

    def the_value(cmd)
      execute(cmd)
    end

    def the_present(cmd)
      execute(cmd).present_value
    end

    def the_future(cmd)
      execute(cmd).future_value
    end

    def the_relative_increase(cmd)
      execute(cmd).relative_increase_percent.rescue_nan.round(1) rescue nil
    end

    def the_absolute_increase(cmd)
      execute(cmd).absolute_increase.rescue_nan.round(1) rescue nil
    end

    def load_scenario(options = {}, &block)
      NastyCache.instance.expire!
      
      scenario = Scenario.new(Scenario.default_attributes.merge options)
      @gql = scenario.gql(prepare: false)
      
      @gql.init_datasets
      instance_eval(&block) if block_given?
      # @gql.update_graphs
      # self.lazy_load_calculate 
      # Above is called when the first numbers are requested through the_future.
      # this allows us to have custom sliders inside "should" do (This works
      # when we initialize load_scenario inside before(:each) and not before(:all)
    end

    # when passing a dynamically created input, make sure
    # to assign lookup_id and update_period.
    def move_slider(id, value)
      input = case id
              when Input then id
              when Numeric then Input.get(id)
              end

      if input
        @user_values_log[input.id] = value
        scenario.update_input(input, value)
      else
        puts "no input found with id #{id.inspect}" 
      end
    end

  protected 

    def scenario
      @gql.scenario
    end

    # --- APIv2 calls -------------------------------------------------------------

    def api_params
      params = {
        settings: {
          area_code:   scenario.area_code,
          end_year:    scenario.end_year,
          use_fce:     scenario.use_fce,
        },
        input:  api_user_values,
        result: @gqueries.uniq
      }
    end

    def api_user_values
      user_values = {}
      scenario.user_values.merge(@user_values_log).each do |k,v|
        user_values[k] = v
      end
      user_values
    end

    def lazy_load_calculate
      unless @gql.calculated?
        @gql.update_graphs
        @gql.calculate_graphs 
      end
    end

    # --- Query -------------------------------------------------------------

    def custom(query)
      lazy_load_calculate
      @_memo[query] ||= @gql.query(query)
    end

    def custom_update(query, value)
      input = Input.new(:key => 'custom', :query => query)
      move_slider(input, value)
    end
    
    def execute(query)
      if query.include?("(")
        custom(query)
      else
        @gqueries << query
        custom(Gquery.get(query))
      end
    end
  end

  
end