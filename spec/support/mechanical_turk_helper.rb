module MechanicalTurkHelper
  class GqlTester
    attr_reader :query_interface

    def initialize(query_interface)
      @query_interface = query_interface
    end
    
    def move_slider(input, value)
      query_interface.execute_input(input, value)
    end

    def custom(query)
      query_interface.query(query)
    end

    def custom_update(query, value)
      input = Input.new(:key => 'custom', :query => query)
      move_slider(input, value)
    end
    
    def method_missing(name, *args)
      custom("Q(#{name})")
    end
  end

  def load_gql(options = {}, &block)
    NastyCache.instance.expire!
    scenario = Scenario.default
    scenario.build_update_statements
    gql = scenario.gql(prepare: false)
    gql.init_datasets
    @future  = GqlTester.new(gql.future)
    @present = GqlTester.new(gql.present)
    instance_eval(&block) if block_given?
    gql.update_graphs
    gql.calculate_graphs
  end

  def move_slider(id, value)
    if input = Input.get(id)
      @future.move_slider(input, value) if input.updates_future?
      @present.move_slider(input, value) if input.updates_present?
    else
      puts "No input found with id #{id.inspect}"
    end
  end
end
