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
    @present.execute(example.description)
  end

  def the_future
    @future.execute(example.description)
  end

  def the_relative_increase
    (((the_future / the_present) - 1.0) * 100.0).round(0)
  end

  def the_absolute_increase
    (the_future - the_present).round(1)
  end

  def load_gql(options = {}, &block)
    NastyCache.instance.expire!
    @scenario = Scenario.new(Scenario.default_attributes.merge options)
    @scenario.build_update_statements
    @gql = @scenario.gql(prepare: false)
    @gql.init_datasets
    @future  = GqlTester.new(@gql.future)
    @present = GqlTester.new(@gql.present)
    @gql.update_graphs
    instance_eval(&block) if block_given?
    @gql.calculate_graphs
  end

  def move_slider(id, value)
    if input = Input.get(id)
      @gql.update_graph(@gql.future, input, value) if input.updates_future?
      #@scenario.inputs_present[input] = value.to_s if input.updates_present?
    else
      puts "No input found with id #{id.inspect}"
    end
  end
end
