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

    def initialize
      @_memo = {}
    end

    def the_present(cmd)
      execute(cmd).present_value
    end

    def the_future(cmd)
      lazy_load_calculate
      execute(cmd).future_value
    end

    def the_relative_increase(cmd)
      execute(cmd).relative_increase_percent.round(1)
    end

    def the_absolute_increase(cmd)
      execute(cmd).absolute_increase.round(1)
    end

    def load_scenario(options = {}, &block)
      NastyCache.instance.expire!
      
      # DEBT. REMOVE Current.scenario!!
      Current.scenario = scenario = Scenario.new(Scenario.default_attributes.merge options)
      scenario.build_update_statements
      @gql = scenario.gql(prepare: false)
      
      @gql.init_datasets
      @gql.update_graphs
      instance_eval(&block) if block_given?
      # self.lazy_load_calculate 
      # Above is called when the first numbers are requested through the_future.
      # this allows us to have custom sliders inside "should" do (This works
      # when we initialize load_scenario inside before(:each) and not before(:all)
    end

    # when passing a dynamically created input, make sure
    # to assign lookup_id and update_period.
    def move_slider(input, value)
      input = case input
              when Input then input
              when Numeric then Input.get(input)
              end

      @gql.update_graph(@gql.future,  input, value) if input.updates_future?
      @gql.update_graph(@gql.present, input, value) if input.updates_present?
    end

  protected 

    def lazy_load_calculate
      @gql.calculate_graphs unless @gql.calculated?
    end

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
        custom("Q(#{query})")
      end
    end
  end

  
end