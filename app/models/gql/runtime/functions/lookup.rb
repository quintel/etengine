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

      # Returns an Array of all {Qernel::Node} for nodes belonging to the energy graph.
      #
      # Use wisely, as this could become a performance killer.
      #
      # Examples
      #
      #   ALL()
      #
      def ALL
        scope.all_energy_nodes
      end

      # Returns an Array of all {Qernel::Node} for nodes belonging to the molecule graph.
      def MALL
        scope.all_molecule_nodes
      end

      # Returns an Array of {Qernel::Node} for given energy group.
      #
      # Examples
      #
      #   GROUP(households)
      #
      def GROUP(*keys)
        scope.group_energy_nodes(keys)
      end
      alias G GROUP

      # Returns an Array of {Qernel::Node} for given molecule group. See GROUP.
      def MGROUP(*keys)
        scope.group_molecule_nodes(keys)
      end
      alias MG MGROUP

      # Returns an Array of {Qernel::Edges} for given energy group.
      #
      # Examples
      #
      #   EDGE_GROUP(households)
      #
      def EDGE_GROUP(*keys)
        scope.group_energy_edges(keys)
      end
      alias EG EDGE_GROUP

      # Returns an Array of {Qernel::Edges} for given molecule group. See EDGE_GROUP.
      def MEDGE_GROUP(*keys)
        scope.group_molecule_edges(keys)
      end
      alias MEG EDGE_GROUP

      # Returns an Array of {Qernel::Node} for given energy sector.
      #
      # Examples
      #
      #   SECTOR(households)
      #
      def SECTOR(*keys)
        scope.energy_sector_nodes(keys)
      end

      # Returns an Array of {Qernel::Node} for given molecule sector. See SECTOR.
      def MSECTOR(*keys)
        scope.molecule_sector_nodes(keys)
      end

      # Returns an Array with {Qernel::Node} for given energy use.
      #
      # See Qernel::Node::USES
      #
      # Examples
      #
      #   USE(energetic)
      #   USE(non_energetic)
      #   USE(undefined)
      #
      def USE(*keys)
        scope.energy_use_nodes(keys)
      end

      # Returns an Array of {Qernel::Carrier} for given key(s). Returns carriers belonging to the
      # energy graph.
      #
      # Examples
      #
      #   CARRIER(electricity) # => [ <Qernel::Carrier electricity> ]
      #   CARRIER(electricity, network_gas) # => [<Qernel::Carrier electricity>, <Qernel::Carrier network_gas>]
      #
      def CARRIER(*keys)
        scope.energy_carriers(keys)
      end

      # Returns an Array of {Qernel::Carrier} for given key(s). Returns carriers belonging to the
      # molecules graph. See CARRIER.
      def MCARRIER(*keys)
        scope.molecule_carriers(keys)
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

      # Public: Retrieves the insulation cost map for a file (new_builds,
      # apartments, etc), then looks up the cost of moving from one level to
      # another.
      #
      # from_level may instead of a string key when looking up costs for new
      # builds.
      #
      # Returns a numeric.
      def INSULATION_COST(file, from_level, to_level)
        scope.graph.insulation_costs(file).get(from_level, to_level)
      end

      # Public: Retrieves a single value from the weather_properties.csv file
      # associated with the currently-selected weather curve set.
      def WEATHER_PROPERTY(key)
        scope.graph.weather_properties.get(key, :value)
      end

      # Public: Describes the total demand of all consumers in the Fever plugin.
      #
      # Returns an array.
      def FEVER_DEMAND(*groups)
        return [] unless Qernel::Plugins::Causality.enabled?(scope.graph)

        plugin = scope.graph.plugin(:time_resolve).fever

        Merit::CurveTools.add_curves(
          groups.map { |group| plugin.summary(group).demand }
        ).to_a
      end

      # Public: Describes the total production in the Fever plugin.
      #
      # Returns an array.
      def FEVER_PRODUCTION(*groups)
        return [] unless Qernel::Plugins::Causality.enabled?(scope.graph)

        plugin = scope.graph.plugin(:time_resolve).fever

        Merit::CurveTools.add_curves(
          groups.map { |group| plugin.summary(group).production }
        ).to_a
      end

      # Public: Creates an array containing the name of all the variants of a
      # curve set available for the current dataset.
      #
      # For example:
      #   CURVE_SET_VARIANTS(heat) => ["default", "1987"]
      #
      # Returns an array of string.
      def CURVE_SET_VARIANTS(name)
        dataset = Atlas::Dataset.find(scope.graph.area.area_code)
        curve_set = dataset.curve_sets.get(name)

        curve_set ? curve_set.map(&:name) : []
      end
    end
  end
end
