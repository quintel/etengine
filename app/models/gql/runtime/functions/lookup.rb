module Gql::Runtime
  module Functions
    module Lookup

      # Returns the present value of the the gquery, when given a key.
      # If the argument is a lambda ( -> { ... }), runs it for the present.
      #
      # @param queryThe gquery lookup key or a lambda with GQL statement
      #
      # @example
      #
      #   QUERY_PRESENT(graph_year)              # => 2010
      #   QUERY_PRESENT( -> { GRAPH(year) } )    # => 2010
      #
      def QUERY_PRESENT(query)
        scope.gql.present.query(query)
      end

      # Returns the future value of the the gquery, when given a key.
      # If the argument is a lambda ( -> { ... }), runs it for the future.
      #
      # @param query The gquery lookup key or a lambda with GQL statement
      # @example
      #
      #   QUERY_FUTURE(graph_year)              # => 2050
      #   QUERY_FUTURE( -> { GRAPH(year) } )    # => 2050
      #
      def QUERY_FUTURE(query)
        scope.gql.future.query(query)
      end

      def QUERY_DELTA(query)
        if scope.present?
          0.0
        else
          QUERY_FUTURE(query) - QUERY_PRESENT(query)
        end
      end

      # Returns the first term for the present graph and the second for
      # the future graph.
      #
      # DEPRECATED: this might not work right now
      #
      def MIXED(present_term, future_term)
        scope.graph.present? ? present_term : future_term
      end

      # Returns an attribute {Qernel::Graph}.
      #
      # keys - The name of the attribute.
      #
      # Advanced
      #
      # GRAPH() without a key returns {Qernel::Graph}
      #
      #   GRAPH() # => <Qernel::Graph>
      #
      # Examples
      #
      #   GRAPH(...) => ...
      #   GRAPH() => <Qernel::Graph>
      #
      def GRAPH(*keys)
        keys.empty? ? scope.graph : scope.graph_query(keys.first)
      end


      # Returns an Array of all {Qernel::Converter}. Use wisely, as this
      # could become a performance killer.
      #
      # Examples
      #
      #   ALL()
      #
      def ALL(*keys)
        scope.all_converters
      end

      # Returns an Array of {Qernel::Converter} for given group.
      #
      # Examples
      #
      #   GROUP(households)
      #
      def GROUP(*keys)
        scope.group_converters(keys)
      end
      alias G GROUP

      # Returns an Array of {Qernel::Links} for given group.
      #
      # Examples
      #
      #   LINK_GROUP(households)
      #
      def LINK_GROUP(*keys)
        scope.group_links(keys)
      end
      alias LG LINK_GROUP

      # Returns an Array of {Qernel::Converter} for given sector.
      #
      # Examples
      #
      #   SECTORS(households)
      #
      def SECTOR(*keys)
        scope.sector_converters(keys)
      end

      # Returns an Array with {Qernel::Converter} for given energy use.
      #
      # See Qernel::Converter::USES
      #
      # Examples
      #
      #   USE(energetic)
      #   USE(non_energetic)
      #   USE(undefined)
      #
      def USE(*keys)
        scope.use_converters(keys)
      end

      # Returns an Array of {Qernel::Carrier} for given key(s)
      #
      # Examples
      #
      #   CARRIER(electricity) # => [ <Qernel::Carrier electricity> ]
      #   CARRIER(electricity, network_gas) # => [<Qernel::Carrier electricity>, <Qernel::Carrier network_gas>]
      #
      def CARRIER(*keys)
        scope.carriers(keys)
      end

      # Returns an attribute {Qernel::Area}
      #
      # keys - The name of the attribute
      #
      # AREA() without a key returns {Qernel::Area}
      #
      #   AREA() # => <Qernel::Area>
      #
      # Examples
      #
      #   AREA(number_of_residences) => 7349500.0
      #
      def AREA(*keys)
        keys.empty? ? scope.graph.area : scope.area(keys.first)
      end

      # Returns the share of an "origin" for a FCE-enabled carrier.
      #
      # @example
      #      FCE_START_VALUE(CARRIER(coal), australia)
      #      FCE_START_VALUE(CARRIER(coal), "australia")
      #
      def FCE_START_VALUE(carrier, country)
        carrier = carrier.first if carrier.is_a?(Array)
        carrier = carrier.key   if carrier.is_a?(Qernel::Carrier)

        scope.graph.plugin(:fce).share_of(carrier, country)
      end

      # Returns a time curve, as stored in the ETSource CSV files, as a hash
      # where each key is a year, and each value is in PJ. You need to specify
      # the name of the time curve and attribute to be read.
      #
      # Only includes from years up to and including the scenario end year.
      #
      # curve     - The name of the time curve to look up. This will match the
      #             name of the CSV in ETSource, minus the "_time_curve" suffix.
      # attribute - Time curves may describe more than one attribute (such as
      #             "preset_demand" and "max_demand"). Specify the attribute to
      #             look up.
      #
      # For example:
      #
      #   TIME_CURVE(energy_extraction_coal, preset_demand)
      #   # => { 2010 => 1.0, 2011 => 42.0, 2012 => 1337.0, ... }
      #
      # Returns a hash.
      def TIME_CURVE(curve, attribute)
        unless data = scope.graph.time_curves[curve]
          fail Gql::TimeCurveError.new(curve)
        end

        unless data.key?(attribute)
          fail Gql::TimeCurveError.new(curve, attribute)
        end

        applicable_years = data[attribute].select do |year, *|
          year <= scope.scenario.end_year
        end

        applicable_years.each_with_object({}) do |(year, joules), data|
          data[year] = joules / 1_000_000_000_000
        end
      end

      # Retrieves the merit order price curve
      def MERIT_PRICE_CURVE
        if Qernel::Plugins::MeritOrder.enabled?(scope.graph)
          scope.graph.plugin(:merit).order.price_curve.to_a
        else
          []
        end
      end

      # Retrieves the merit load curves
      def MERIT_LOAD_CURVES(part_key)
        if Qernel::Plugins::MeritOrder.enabled?(scope.graph)
          if participant = scope.graph.plugin(:merit).order.participants[part_key]
            participant.load_curve.to_a
          else
            fail "No such merit order participant: #{ part_key.inspect }"
          end
        else
          []
        end
      end
    end

  end
end
