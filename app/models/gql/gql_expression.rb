module Gql

class GqlExpression < Treetop::Runtime::SyntaxNode
  ##
  # Functions that should evaluate the value_terms itself.
  # We treat them as exceptions because the majority of functions
  # just need the values. We don't want to repeat ourselves in all
  # those methods not listed in this constant.
  #
  LAZY_CALCULATE_VALUE_TERMS = %w[IF RESCUE FOR_COUNTRIES EACH UPDATE]

  def result( value_terms, params, scope )
    # DEBT this is not really needed as we check for query correctness
    # if respond_to?(text_value)
    if !LAZY_CALCULATE_VALUE_TERMS.include?(text_value)
      value_terms.map!{|value_term| value_term.result(scope) }
    end
    send(text_value, value_terms, params, scope)
    # else
    #   raise GqlError.new("GQL: No such function defined: #{text_value}")
    # end
  end

  def debug(*args)
    keys, arguments, scope, msg = args
    result = send(text_value, keys, arguments, scope)
    msg << "#{result} - #{text_value} #{keys} #{arguments}"
    result
  end

  ##
  # VALUE returns the attributes for a set of Converters.
  #
  # Note that duplicate converters are removed, so that
  #    VALUE(foo; bar) == VALUE(foo, foo; bar)
  #
  # == How to use:
  #
  #   VALUE( list of converters ; attribute )
  #   More exact:
  #   VALUE([Array<Converter>],[Array<Converter>] ; ruby code run inside this objects)
  #
  #
  # === Getting values form *multiple* objects
  #
  #   VALUE(foo,bar,etc; attribute_name)
  #   => [3.0,2.0,5.0]
  #   SUM( VALUE(foo,bar,etc; attribute_name) )
  #   => 10.0
  #
  # === Arbitrary complex select and attribute definition
  #
  #   VALUE( GROUP(households), GROUP(industry) ; output_demand * -1.5 )
  #   # translates internally into:
  #   # VALUE( [households_foo, households_bar], [industry_foo, industry_bar] ; output_demand * - 1.5)
  #   # translates internally into:
  #   # VALUE( households_foo, households_bar, industry_foo, industry_bar ; output_demand * - 1.5)
  #
  # == Special uses
  #
  # === Get a value from a *carrier*
  #
  # We can use the VALUE method also to get values from other objects, mainly CARRIER.
  #
  #   VALUE( CARRIER(electricity, useable_heat); co2_per_mj )
  #
  # === Getting values from *one* object:
  #
  #   VALUE(foo; attribute_name)
  #   => 3.0
  #
  # Notice that a Float is returned and not an Array of one Float. This has the advantage
  # that we don't have to add a SUM-function.
  #
  # === Use VALUE to define a collection of converters.
  #
  # Sometimes we want to make a GQL Subquery, that just returns a set of converters. E.g. coal_plants
  #
  #   VALUE(foo)
  #   => foo
  #   more complex:
  #   VALUE( foo, VALUE(foo,bar))
  #   => [foo, bar] # Note that foo only appears once. So duplicates are removed
  #
  # We can now store the latter query into a Gquery and access them later.
  #
  #   foo_bar_converters: VALUE( foo, bar )
  #   SUM( VALUE( Q(foo_bar_converters); demand) )
  #
  #
  # @param keys [Array<String,Array>] A list of converters.
  # @param attribute_name [String] A ruby expression that is instance_evaled for the selected converters.
  # @return [Array<Float>]
  # @return [Array<Qernel::ConverterApi>] if no attribute_name is defined.
  #
  # TODO refactor
  #
  def VALUE(converters, attribute_name, scope = nil)
    converters.flatten!
    converters.map!{|key| key.is_a?(String) ? scope.converters(key) : key}

    if attribute_name and !attribute_name.empty?
      # converters is a nested array [[[],[]],[]]
      # we might have doubles (e.g. when SECTOR(foo), GROUP(bar))
      flatten_uniq(converters) 

      attr_name = replace_gql_with_ruby_brackets(attribute_name.first)

      converters.map! do |c|
        begin
          if c.respond_to?(:query)
            # We don't access Converter directly, but through their converter_api objects
            # which we get with #query
            c.query.instance_eval(attr_name)
          else
            # c in this case is most probably a Carrier (we don't get other data)
            c.instance_eval(attr_name)
          end
        end
      end

      values = converters

      
      # hmm. If we only have one value, return value instead of array with single value
      #   somehow weird behaviour...
      values.length <= 1 ? (values.first || 0.0) : values
    else
      flatten_uniq(converters)#.tap(&:flatten!)
    end
  end
  alias V VALUE

  ##
  # Arguments of VALUE are normal ruby instance_eval's. But because
  # we use brackets '(' ')' for defining GQL queries. we use '[', ']'
  # within GQL to define normal ruby brackets.
  #
  # e.g. V(converter; [demand + co2] ** 3)
  #
  def replace_gql_with_ruby_brackets(attr_name)
    if attr_name.include?('[')
      attr_name.strip!
      attr_name.gsub!('[','(')
      attr_name.gsub!(']',')')
      attr_name
    else
      attr_name.tap(&:strip!)
    end
  end

  ##
  # All Converters in the graph. Use wisely.
  #
  # @return [Array<Qernel::ConverterApi] All converters
  #
  def ALL(keys, arguments, scope)
    scope.all_converters
  end

  # Executes a subquery with the given key (all stored Gqueries (see /admin/gqueries) can act as subquery): *QUERY( total_energy_cost )*
  #
  # @param keys [String] The key of the subquery (Gquery)
  # @return The result of the subquery
  #
  def QUERY(keys, arguments, scope)
    scope.subquery(keys.first)
  end
  alias Q QUERY
  # @deprecated
  alias SUBQUERY QUERY

  

  #     Gquery.create(:key => 'graph_year', :query => "GRAPH(year)")
  #
  #     Current.gql.query("Q(graph_year)")
  #     # => 2010, 2040
  # 
  #     Current.gql.query("QUERY_PRESENT(graph_year)")
  #     # => 2010, 2010
  #   
  #     Current.gql.query("QUERY_FUTURE(graph_year)")
  #     # => 2040, 2040
  #   
  #     # 2040 - 2010
  #     Current.gql.query("SUM(QUERY_FUTURE(graph_year),NEG(QUERY_PRESENT(graph_year)))")
  #     # => 30, 30 
  #   
  #     # prefixing it with future/present has no influence
  #     Current.gql.query("present:SUM(QUERY_FUTURE(graph_year),NEG(QUERY_PRESENT(graph_year)))")
  #     # => 30, 30 
  #
  # @param keys [String] Key of a subquery that is run in the present
  # @return [Float] The return value of the subquery
  #
  def QUERY_PRESENT(keys, arguments, scope)
    Current.gql.present.subquery(keys.first)
  end

  # @param keys [String] Key of a subquery that is run in the future
  # @return [Float] The return value of the subquery
  #
  def QUERY_FUTURE(keys, arguments, scope)
    Current.gql.future.subquery(keys.first)
  end

  ##
  # Children of a converter(s).
  # e.g.
  #   CHILDREN(V(small_chp_industry_energetic))
  #
  # @param converters [String] converters
  # @return [Array<Qernel::ConverterApi>] direct children of the converters
  #
  def CHILDREN(converters, arguments, scope)
    flatten_uniq(converters.tap(&:flatten!).map{|c| c.converter.children})
  end

  ##
  # Direct parents of a converter(s).
  # e.g.
  #   PARENTS(V(small_chp_industry_energetic))
  #
  # @param converters [String] converters
  # @return [Array<Qernel::ConverterApi>] direct parents of the converters
  #
  def PARENTS(converters, arguments, scope)
    flatten_uniq(converters.tap(&:flatten!).map{|c| c.converter.parents})
  end

  ##
  # Selects only the converters that return true to the given 
  # instance_evaled ruby string.
  #
  # FILTER(ALL(); electricity_input > 0)
  #
  # @param converters [String] converters
  #
  def FILTER(converters, filter_name, scope)
    inst_eval = replace_gql_with_ruby_brackets(filter_name.first)
    flatten_uniq(converters.tap(&:flatten!).select{|c| c.query.instance_eval(inst_eval) })
  end

  def FIRST(value_terms, arguments, scope)
    value_terms.flatten.first
  end

  def LINK(value_terms, arguments, scope)
    a,b = VALUE(value_terms, arguments, scope)
    if a.nil? || b.nil?
      nil
    else
      link = a.input_links.detect{|l| l.child == b.converter}
      link ||= a.output_links.detect{|l| l.parent == b.converter}
      link
    end
  end

  def LINKS(value_terms, arguments, scope)
    value_terms.flatten.compact.map(&:links)
  end

  # OUTPUT_SLOTS(converter_key; carrier)
  # OUTPUT_SLOTS(V(converter_key); carrier)
  #
  def OUTPUT_SLOTS(value_terms, arguments, scope)
    converters = VALUE(value_terms, nil, scope)
    carrier = arguments.first
    flatten_uniq converters.compact.map{|c| carrier ? c.output(carrier.to_sym) : c.outputs}
  end

  # INPUT_SLOTS(converter_key; carrier)
  # INPUT_SLOTS(V(converter_key); carrier)
  #
  def INPUT_SLOTS(value_terms, arguments, scope)
    converters = VALUE(value_terms, nil, scope)
    carrier = arguments.first
    flatten_uniq converters.compact.map{|c| carrier ? c.input(carrier.to_sym) : c.outputs}
  end

  def INPUT_LINKS(value_terms, arguments, scope)
    links = flatten_uniq(value_terms.tap(&:flatten!).map(&:input_links))
    if arguments.first
      inst_eval = replace_gql_with_ruby_brackets(arguments.first)
      links.select!{|link| link.instance_eval(inst_eval) } 
    end
    links
  end

  def OUTPUT_LINKS(value_terms, arguments, scope)
    links = flatten_uniq(value_terms.tap(&:flatten!).map(&:output_links))
    if arguments.first
      inst_eval = replace_gql_with_ruby_brackets(arguments.first)
      links.select!{|link| link.instance_eval(inst_eval) } 
    end
    links
  end

  ##
  # Converters of a {Qernel::Group Group}: *GROUP(primary_demand_cbs)*
  #
  # @param keys [Array<String>] Group key(s)
  # @return [Array<Qernel::ConverterApi>]
  #
  def GROUP(keys, arguments, scope)
    scope.group_converters(keys)
  end
  alias G GROUP

  ##
  # Converters of a sector : *SECTOR(households)*
  #
  # @see Qernel::Converter::SECTORS list of sectors
  # @param keys [Array<String>] Sector key(s)
  # @return [Array<Qernel::ConverterApi>]
  #
  def SECTOR(keys, arguments, scope)
    scope.sector_converters(keys)
  end

  ##
  # Converters of a "energy use": energetic, non_energetic, undefined: *USE(energetic)*
  #
  # @see Qernel::Converter::USE list of energy uses
  # @param keys [Array<String>] Use key(s)
  # @return [Array<Qernel::ConverterApi>]
  #
  def USE(keys, arguments, scope)
    scope.use_converters(keys)
  end

  ##
  # {Qernel::Carrier Carrier} with the keys: *CARRIER(electricity)*
  #
  # @param keys [Array<String>] Carrier key(s)
  # @return [Array<Qernel::Carrier>]
  #
  def CARRIER(keys, arguments, scope)
    scope.carriers(keys)
  end

  ##
  # {Qernel::Area Graph} attribute of current country: *AREA(available_land)*
  #
  # @param keys [String] Attribute of area
  # @return [Float]
  #
  def AREA(keys, arguments, scope)
    scope.area(keys.first)
  end

  # Returns a Qernel::Goal object with the key passed as parameter.
  # The object will be created if it doesn't exist
  #
  def GOAL(keys, arguments, scope)
    scope.graph.find_or_create_goal(keys.first.to_sym)
  end
  
  # returns a boolean whether the user has set a goal or not.
  # I'd rather have the VALUE(GOAL(foo); user_value) return nil, but
  # now falsy values are converted to 0.0 unfortunately.
  #
  def GOAL_IS_SET(keys, arguments, scope)
    GOAL(keys, arguments, scope).is_set?
  rescue
    nil
  end
  
  # Shortcut for
  # V(GOAL(foobar);user_value)
  #
  def GOAL_USER_VALUE(keys, arguments, scope)
    GOAL(keys, arguments, scope).user_value
  end

  # {Qernel::GraphApi Graph} attributes: *GRAPH(method)*
  #
  # @see Qernel::GraphApi
  # @param keys [String] GraphApi method
  # @return [Float]
  #
  def GRAPH(keys, arguments, scope)
    scope.graph_query(keys.first)
  end

  # Returns a time_serie value of a given year. 
  # DEBT: eventually refactor this into a more general set of Hash lookup.
  #
  # @param converter_id [Numeric]
  # @param value_type [String]
  # @param year [Numeric]
  # @return [Float] Value of time serie
  #
  def TIME_SERIE_VALUE(keys, arguments, scope)
    converter_id, time_curve_key, year = keys.flatten
    scope.graph.time_curves[converter_id.to_i][time_curve_key][year.to_i] rescue nil
  end

  # Returns the intersection of two sets of converters.
  #
  # e.g.
  #   INTERSECTION([dennis,willem,alexander],[sebastian,dennis,willem])
  #   => [dennis,willem]
  #
  # It is mostly used to get an intersection of a group and a sector:
  # e.g.
  #   INTERSECTION(GROUP(heat_production),SECTOR(industry))
  #
  # Note that it only works with two arguments.
  #
  # Bad:
  #   INTERSECTION(GROUP(team_members),dennis,willem)
  # Good:
  #   INTERSECTION(GROUP(team_members),V(dennis,willem))
  #
  # @param keys [Array<Object>,Array<Object>] Intersection of two converter arrays
  # @return [Array<Object>]
  #
  def INTERSECTION(keys, arguments, scope = nil)
    keys.first.flatten & keys.last.flatten
  end

  ##
  # 
  #
  # e.g.
  #   EXCLUDE([dennis,willem,alexander],[dennis])
  #   => [willem,alexander]
  #
  # TODO: document this properly
  #
  # @param keys [Array<Object>,Array<Object>]
  # @return [Array<Object>]
  #
  def EXCLUDE(keys, arguments, scope = nil)
    keys.first.flatten - keys.last.flatten
  end

  ###################################
  # Calculation functions (on values)
  #
  # @param [Array<Float>]
  # @return Float
  ###################################

  ##
  # How many (non-nil) values are there?
  #
  # @param values [Array<Object>]
  # @return [Integer] Size of array (ignoring nil values)
  #
  def COUNT(values, arguments, scope = nil)
    flatten_compact(values).count
  end

  ##
  # convert nil values to zero values
  #
  # @param values [Float,Array<Numeric>]
  # @return [Float,Array<Numeric>] Array with nil values converted to zero
  #
  def NIL_TO_ZERO(values, arguments, scope = nil)
    if values.respond_to?(:map)
      values.tap(&:flatten!).map!{|v| v.nil? ? 0 : v }
      values
    else
      values.nil? ? 0 : v
    end
  end

  ##
  # converts nil and NaN values to zero values
  #
  # @param values [Float,Array<Numeric>]
  # @return [Float,Array<Numeric>] Array with nil or NaN values converted to zero
  #
  def INVALID_TO_ZERO(values, arguments, scope = nil)
    is_invalid = Proc.new {|v| v.nil? || (v.respond_to?(:nan?) && v.nan?) }

    if values.respond_to?(:map)
      values.tap(&:flatten!).map!{|v| is_invalid.call(v) ? 0 : v }
      values
    else
      is_invalid.call(values) ? 0 : v
    end
  end

  ##
  # Sum of a list of values.
  #
  # @param values [Array<Numeric>]
  # @return [Float] Sum of values (ignoring nil values)
  #
  def SUM(values, arguments, scope = nil)
    flatten_compact(values).inject(0) {|total,value| total += value}
  end

  ##
  # @param values [Array<Numeric>]
  # @return [Float] Average of values (ignoring nil values)
  #
  def AVG(values, arguments, scope = nil)
    SUM(values, nil) / COUNT(values, nil)
  end


  ##
  # PRODUCT(1,2,3) => 1 * 2 * 3 => 6
  #
  # @param values [Array<Numeric>]
  # @return [Float] Product of all values (ignoring nil values).
  #
  def PRODUCT(values, arguments, scope = nil)    
    flatten_compact(values).inject(1) {|total,value| total = total * value}
  end

  ##
  # @param values [Float,Float]
  # @return [Float]
  #
  def DIVIDE(values, arguments, scope = nil)
    a,b = values.tap(&:flatten!)
    if a == 0.0 || a.nil?
      0.0
    else
      a / b
    end
  end

  ##
  # @param values [Array<Float>]
  # @return [Float] the highest number
  #
  def MAX(values, arguments, scope = nil)
    flatten_compact(values).max
  end

  ##
  # @param values [Array<Float>]
  # @return [Float] the lowest number
  #
  def MIN(values, arguments, scope = nil)
    flatten_compact(values).min
  end

  ##
  # @param values [Array<Float>]
  # @return [Array<Float>] absolute numbers
  #
  def ABS(values, arguments, scope = nil)
    values = flatten_compact(values).map!{|v| v.abs if v }
    values
  end

  # NORMCDF(upper_boundary, mean, std_dev)
  #
  # @param values [Array<Float>] upper_boundary, mean, std_dev
  # @return [Float] 
  #
  def NORMCDF(values, arguments, scope = nil)
    # lower_Boundary is always -Infinity
    upper_boundary, mean, std_dev = flatten_compact(values)
    Distribution::Normal.cdf( (upper_boundary.to_f - mean.to_f) / std_dev.to_f )
  end

  # SQRT(2) => [4]
  # SQRT(2,3) => [4,9]
  # SUM(SQRT(2,3)) => 13
  #
  # @param values [Array<Float>] upper_boundary, mean, std_dev
  # @return [Float] 
  #
  def SQRT(values, arguments, scope = nil)
    flatten_compact(values).map{|v| Math.sqrt(v) }
  end

  ###################################
  # Comparison Operators
  #
  # @param [Float,Float]
  # @return [-1,0,1]
  ###################################

  ##
  # @param values [Float,Float] Two values.
  # @return [-1,0,1]
  #
  def COMPARE(values, arguments, scope = nil)
    a,b = values
    modifier = arguments.first
    if modifier and digits = modifier[/^round_(\d)$/,1]
      a = a.round(digits.to_f)
      b = b.round(digits.to_f)
    end
    a <=> b
  end

  ##
  # LESS(1,2) => true
  # LESS(1,1) => false
  #
  # @param values [Float,Float]
  # @return [Boolean] true if first is less then second
  #
  def LESS(values, arguments, scope = nil)
    a,b = values
    a < b
  end

  ##
  # LESS_OR_EQUAL(1,1) => true
  #
  # @param values [Float,Float]
  # @return [Boolean] true if first is less or equal then second
  #
  def LESS_OR_EQUAL(values, arguments, scope = nil)
    a,b = values
    a <= b rescue nil
  end

  ##
  # GREATER(2,1) => true
  #
  # @param values [Float,Float]
  # @return [Boolean] true if first is greater then second
  #
  def GREATER(values, arguments, scope = nil)
    a,b = values
    a > b rescue false # FIX to make certain gqueries run with municipalities
    # nil would be better if the comparison fails
  end

  ##
  # @param values [Float,Float]
  # @return [Boolean] true if first is greater or equal then second
  #
  def GREATER_OR_EQUAL(values, arguments, scope = nil)
    a,b = values
    a >= b
  end

  ##
  # @param values [Float,Float]
  # @return [Boolean] true if first equals second
  #
  def EQUALS(values, arguments, scope = nil)
    a,b = values
    a == b
  end

  ##
  # @param values [Boolean]
  # @return [Boolean] inverse of values
  #
  def NOT(values, arguments, scope = nil)
    !(values.first == true)
  end

  ##
  # @param values [Array<Boolean>]
  # @return [Boolean] Any of the values true?
  #
  def OR(values, arguments, scope = nil)
    values.any?{|v| v == true }
  end

  ##
  # Is the value a number (and not nil or s'thing else).
  #
  # @param value [Float]
  # @return [Boolean] Is the argument a numeric
  #
  def IS_NUMBER(value, arguments, scope = nil)
    value.first.is_a?(Numeric)
  end

  ##
  # checks if value is nil
  #
  # @param value [Float]
  # @return [Boolean] Is the argument a numeric
  #
  def IS_NIL(value, arguments, scope = nil)
    value.first == nil
  end


  ##
  # Excecutes statement only if Current.scenario.country is in parameter list.
  #
  # Note: separate countries with ";"
  #
  # e.g.
  #   FOR_COUNTRIES(5;de;en;it)
  #   # if Current.scenario.country is in the parameter list
  #   => 5
  #   => if not.
  #   => nil
  #
  # TODO: document properly
  # @return [Object] value or nil if not in country
  #
  def FOR_COUNTRIES(value_terms, arguments, scope = nil)
    # DEBT: fix Current.scenario.country to use graph
    if arguments.include?(Current.scenario.country)
      value_terms.map!{|value_term| value_term.result(scope) }
      value_terms.length == 1 ? value_terms.first : value_terms
    else
      nil
    end
  end

  ##
  # If statement, with a check clause (condition) and two values.
  #
  #   IF( condition , value if true , value if false )
  #
  # e.g.
  #   s
  #   => 0
  #   IF(LESS(1,3),IF(LESS(3,1),50,10),100)
  #   => 10
  #
  #
  # @param statements [Array<Boolean,Object>] Expects 3 statements: condition, value if true, value if false
  # @raise [GqlError] if condition statement is not boolean
  # @raise [GqlError] if arguments does not contain 3 statements
  # @return [Object]
  #
  def IF(value_terms, arguments, scope = nil)
    condition, if_true, if_false = value_terms
    condition_result = condition.result(scope)
    raise GqlError.new("IF statement (#{condition.text_value}) returns '#{condition_result.inspect}' instead of a boolean") unless [true, false].include?(condition_result)
    raise GqlError.new("IF statement is missing arguments") unless if_true && if_false
    condition_result ? if_true.result(scope) : if_false.result(scope)
  end

  ##
  # Returns the parameter value (or 0.0 as default) if an error is raised in the value.
  #
  # e.g.
  #   RESCUE( DIVIDE(NIL(),5))
  #   => 0.0
  #   # with custom return value
  #   RESCUE( DIVIDE(NIL(),5); 100.0)
  #   => 100.0
  #   # If no errors returns value
  #   RESCUE( SUM(1,2); 100.0)
  #   => 3.0
  #
  # @return [Object] returns the value or the parameter if rescues an exception
  #
  def RESCUE(value_terms, params, scope = nil)
    rescue_value = params.andand.first || 0.0
    values = value_terms.map{|term| term.result(scope) rescue rescue_value }
    values.length == 1 ? values.first : values
  end

  ##
  # Returns a nil value. mainly used for testing.
  # e.g.
  #   NIL()
  #
  def NIL(statement,arguments,scope = nil)
    nil
  end

  ###################################
  # (Single) Number Operation
  #
  # There's no specific reason, why we cannot apply the operation
  #  on an array of numbers and return that array, but somehow it
  #  feels less confusing to limit those operations to one number.
  #
  # @param [Array<Float>]
  # @return Float
  ###################################


  ##
  #
  # @param values [Float]
  # @return [Float] -(value)
  #
  def NEG(values, arguments, scope = nil)
    values = flatten_compact(values).map!{|v| v * -1.0}
    values.first
  end

  ##
  # Converts a value to another format. Know what you do!
  # Especially useful to write more readable Queries:
  #
  #   PRODUCT(0.15,100) => 15.0 (%)
  #   vs.
  #   UNIT(0.15;percentage) => 15.0 (%)
  #
  # @param values [Float]
  # @return [Float] Converted value
  #
  def UNIT(values, arguments, scope = nil)
    Unit.convert_to(values.first, arguments.first)
  end

  ##
  # @param values [Float]
  # @return [Float] 1 / x of value
  #
  def INVERSE(values, arguments, scope = nil)
    1.0 / values.first
  end

  def flatten_compact(arr)
    arr.tap(&:flatten!).tap(&:compact!)
  end

  def flatten_uniq(arr)
    arr.tap(&:flatten!).tap(&:uniq!)
  end

  # -------- UPDATE -----------------------------------------------------------

  def EACH(value_terms, arguments, scope = nil)
    value_terms.each do |value_term|
      value_term.result(scope)
    end
  end

  # Its syntax is:
  # 
  # UPDATE(object(s),attribute,value)
  #
  def UPDATE(value_terms, arguments, scope = nil)
    update_statement = value_terms.pop
    attribute_name   = value_terms.pop.result(scope)
    objects = value_terms.map{|object| object.result(scope)}.flatten

    scope.update_collection = objects # for UPDATE_COLLECTION()
    objects.each do |object|
      object = object.query if object.respond_to?(:query)

      if object
        scope.update_object = object # for UPDATE_OBJECT()

        input_value = update_statement.result(scope)

        object[attribute_name] = case update_strategy(scope)
        when :absolute then input_value
        when :relative_total
          cur_value = BigDecimal(object[attribute_name].to_s)
          cur_value + (cur_value * input_value)
        when :relative_per_year
          cur_value = BigDecimal(object[attribute_name].to_s)
          cur_value * ((1.0 + input_value) ** Current.scenario.years)
        end.to_f
      else
        raise "UPDATE: objects not found: #{value_terms.map(&:text_value)}"
      end
    end
  ensure
    scope.update_collection = nil
    scope.update_object = nil
  end

  # at the moment only takes care of percentages and absolute numbers.
  #
  def input_factor(scope)
    if scope.input_value.andand.include?('%')
      100.0
    else 
      1.0
    end
  end

  def update_strategy(scope)
    input = scope.input_value
    if input.is_a?(String)
      if input.include?('%y') 
        :relative_per_year
      elsif input.include?('%') 
        :relative_total
      else
        :absolute
      end
    else
      :absolute
    end
  end

  def USER_INPUT(values, arguments, scope = nil)
    input = scope.input_value
    input_float = if input.is_a?(String)
      # We need to use BigDecimal for pretty numbers (try in irb: 1.15 * 100.0)
      BigDecimal(input)
    else
      input
    end
    input_float / input_factor(scope)
  end

  def UPDATE_OBJECT(values, arguments, scope = nil)
    if scope.update_object
      scope.update_object
    else
      raise "GQL SELF() has to be inside UPDATE and a valid object has to be defined"
    end
  end

  def UPDATE_COLLECTION(values, arguments, scope = nil)
    if scope.update_collection
      scope.update_collection
    else
      raise "GQL SELF() has to be inside UPDATE and a valid object has to be defined"
    end
  end
  
  # With this function you can run two different statements for present and future.
  # 
  def MIXED(value_terms, arguments, scope = nil)
    present_term = value_terms[0]
    future_term  = value_terms[1]
    scope.graph.present? ? present_term : future_term
  end

  def PRESENT_ONLY(value_terms, arguments, scope = nil)
    value_terms if scope.graph.present?
  end

  def FUTURE_ONLY(value_terms, arguments, scope = nil)
    value_terms unless scope.graph.present?
  end
end

end
