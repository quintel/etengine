module Gql

class GqlExpression < Treetop::Runtime::SyntaxNode
  ##
  # Functions that should evaluate the value_terms itself.
  # We treat them as exceptions because the majority of functions
  # just need the values. We don't want to repeat ourselves in all
  # those methods not listed in this constant.
  #
  LAZY_CALCULATE_VALUE_TERMS = %w[IF RESCUE FOR_COUNTRIES]

  def result( value_terms, params, scope )
    # DEBT this is not really needed as we check for query correctness
    # if respond_to?(text_value)
    if LAZY_CALCULATE_VALUE_TERMS.include?(text_value)
      send(text_value, value_terms, params, scope)
    else
      values = value_terms.map{|value_term| value_term.result(scope) }
      send(text_value, values, params, scope)
    end
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
    if attribute_name and !attribute_name.empty?
      converters.map!{|key| key.is_a?(String) ? scope.converters(key) : key}

      converters.flatten! # converters is a nested array [[[],[]],[]]
      converters.uniq!    # we might have doubles (e.g. when SECTOR(foo), GROUP(bar))

      attr_name = replace_gql_with_ruby_brackets(attribute_name.first)

      values = converters.map do |c|
        begin
          if c.respond_to?(:query)
            # We don't access Converter directly, but through their converter_api objects
            # which we get with #query
            c.query.instance_eval(attr_name)
          else
            # c in this case is most probably a Carrier (we don't get other data)
            c.instance_eval(attr_name)
          end
        rescue Exception => e
          raise "VALUE(#{converters.join(',')};#{attribute_name.first.strip.gsub('[','(').gsub(']',')')}) for #{c.full_key} throws an exception: #{e}"
        end
      end

      # hmm. If we only have one value, return value instead of array with single value
      #   somehow weird behaviour...
      values.length <= 1 ? (values.first || 0.0) : values
    else
      [
        # for all strings in converters lookup converter
        scope.converters(converters.select{|k| k.is_a?(String) }), 
        # all Converters within converters
        converters.reject{|k| k.is_a?(String) } 
      ].flatten
    end
  end
  alias_method :V, :VALUE

  ##
  # Arguments of VALUE are normal ruby instance_eval's. But because
  # we use brackets '(' ')' for defining GQL queries. we use '[', ']'
  # within GQL to define normal ruby brackets.
  #
  # e.g. V(converter; [demand + co2] ** 3)
  #
  def replace_gql_with_ruby_brackets(attr_name)
    if attr_name.include?('[')
      attr_name.strip.gsub('[','(').gsub(']',')')
    else
      attr_name.strip
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

  ##
  # Executes a subquery with the given key (all stored Gqueries (see /admin/gqueries) can act as subquery): *QUERY( total_energy_cost )*
  #
  # @param keys [String] The key of the subquery (Gquery)
  # @return The result of the subquery
  #
  def QUERY(keys, arguments, scope)
    scope.subquery(keys.first)
  end
  alias_method :Q, :QUERY
  # @deprecated
  alias_method :SUBQUERY, :QUERY

  ##
  # Children of a converter(s).
  # e.g.
  #   CHILDREN(V(small_chp_industry_energetic))
  #
  # @param converters [String] converters
  # @return [Array<Qernel::ConverterApi>] direct children of the converters
  #
  def CHILDREN(converters, arguments, scope)
    converters.flatten.map{|c| c.converter.children}.flatten.uniq
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
    converters.flatten.map{|c| c.converter.parents}.flatten.uniq
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
    converters.flatten.select{|c| c.query.instance_eval(inst_eval) }.flatten.uniq
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
  alias_method :G, :GROUP

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

  ##
  # Goal (or target) for some policy
  # e.g.
  #   GOAL(co2_emission)
  # The target value might be calculated on top of the user_set value
  # ie when the user sets a factor to increase/decrease something
  #
  # @param keys indentifies the policy goal to check
  # @return [Float]
  # @return [Array<Qernel::ConverterApi] All converters
  #
  def GOAL(keys, arguments, scope)
    Current.gql.policy.goal(keys.first.to_sym).target_value
  end

  #
  # @param keys name of the policy goal
  # @return [Float]
  #
  # This is what the user has set. If he didn't set any value
  # we'll get nil. Notice that the target value might be a
  # different value
  #
  def GOAL_USER_VALUE(keys, arguments, scope)
    Current.gql.policy.goal(keys.first.to_sym).user_value
  end

  ##
  # {Qernel::GraphApi Graph} attributes: *GRAPH(method)*
  #
  # @see Qernel::GraphApi
  # @param keys [String] GraphApi method
  # @return [Float]
  #
  def GRAPH(keys, arguments, scope)
    scope.graph_query(keys.first)
  end

  ##
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
  # Returns the intersection of two sets of converters.
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
    values.flatten.compact.count
  end

  ##
  # convert nil values to zero values
  #
  # @param values [Float,Array<Numeric>]
  # @return [Float,Array<Numeric>] Array with nil values converted to zero
  #
  def NIL_TO_ZERO(values, arguments, scope = nil)
    if values.respond_to?(:map)
      values.flatten.map{|v| v.nil? ? 0 : v }
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
      values.flatten.map{|v| is_invalid.call(v) ? 0 : v }
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
    values.flatten!
    values.compact!
    values.inject(0) {|total,value| total += value}
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
    values.flatten!
    values.compact!
    values.inject(1){|total,value| total = total * value}
  end

  ##
  # @param values [Float,Float]
  # @return [Float]
  #
  def DIVIDE(values, arguments, scope = nil)
    a,b = values.flatten
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
    values.flatten!
    values.compact!
    values.max
  end

  ##
  # @param values [Array<Float>]
  # @return [Float] the lowest number
  #
  def MIN(values, arguments, scope = nil)
    values.flatten!
    values.compact!
    values.min
  end

  ##
  # @param values [Array<Float>]
  # @return [Array<Float>] absolute numbers
  #
  def ABS(values, arguments, scope = nil)
    values.flatten!
    values.compact!
    values.map!{|v| v.abs if v }
    values
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
    a <= b
  end

  ##
  # GREATER(2,1) => true
  #
  # @param values [Float,Float]
  # @return [Boolean] true if first is greater then second
  #
  def GREATER(values, arguments, scope = nil)
    a,b = values
    a > b
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
      values = value_terms.map{|value_term| value_term.result(scope) }
      values.length == 1 ? values.first : values
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
    values.flatten!
    values.compact!
    values.map!{|v| v * -1.0}
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
    arr.flatten.compact
  end
end

end
