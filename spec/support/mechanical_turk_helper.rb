module MechanicalTurkHelper
  class GqlTester
    attr_reader :query_interface

    def initialize(query_interface)
      @_memo = {}
      @query_interface = query_interface
    end
    
    def move_slider(input, value)
      query_interface.execute_input(input, value)
    end

    def custom(query)
      @_memo[query] ||= query_interface.query(query)
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

    def method_missing(name, *args)
      custom("Q(#{name})")
    end
  end

  def some_tolerance
    @some_tolerance ||= ENV.fetch('TOLERANCE', 3.0)
  end

  def the_present
    lazy_load_calculate
    @present.execute(example.description)
  end

  def the_future
    lazy_load_calculate
    @future.execute(example.description)
  end

  def the_relative_increase
    (((the_future / the_present) - 1.0) * 100.0).round(1)
  end

  def the_absolute_increase
    (the_future - the_present).round(1)
  end

  def lazy_load_calculate
    @gql.calculate_graphs unless @gql.calculated?
  end

  def load_scenario(options = {}, &block)
    NastyCache.instance.expire!
    @scenario = Scenario.new(Scenario.default_attributes.merge options)
    Current.scenario = @scenario
    @scenario.build_update_statements
    @gql = @scenario.gql(prepare: false)
    # @gql.sandbox_mode = :console
    @gql.init_datasets
    @future  = GqlTester.new(@gql.future)
    @present = GqlTester.new(@gql.present)
    @gql.update_graphs
    instance_eval(&block) if block_given?
    # lazy_load_calculate 
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
end
