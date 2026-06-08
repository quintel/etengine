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
      #   AREA(present_number_of_residences) => 7349500.0
      #
      def AREA(*keys)
        keys.empty? ? scope.graph.area : scope.area(keys.first)
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

      # Public: A curve describing the production in MWh of a specific producer
      # for a specific consumer within Fever
      #
      # Returns an array
      def FEVER_PRODUCTION_CURVE_FOR_COUPLE(producer, consumer)
        return [] unless Qernel::Plugins::Causality.enabled?(scope.graph)

        producer = producer.first
        consumer = consumer.first

        return [] unless producer.fever

        plugin = scope.graph.plugin(:time_resolve).fever
        group = producer.fever.group

        plugin.summary(group).production_curve_for(producer.key, consumer.key)
      end

      # Public: A curve describing the demand in MWh of a specific consumer
      # on a specific producer within Fever
      #
      # Returns an array
      def FEVER_DEMAND_CURVE_FOR_COUPLE(producer, consumer)
        return [] unless Qernel::Plugins::Causality.enabled?(scope.graph)

        producer = producer.first
        consumer = consumer.first

        return [] unless producer.fever

        plugin = scope.graph.plugin(:time_resolve).fever
        group = producer.fever.group

        plugin.summary(group).demand_curve_for(producer.key, consumer.key)
      end

      # Public: A curve describing the production in MWh of/for a specific consumer
      # or producer within Fever
      #
      # Returns an array
      def FEVER_PRODUCTION_CURVE(node)
        return [] unless Qernel::Plugins::Causality.enabled?(scope.graph)

        node = node.first
        return [] unless node.fever

        plugin = scope.graph.plugin(:time_resolve).fever
        group = node.fever.group

        if node.fever.type == :consumer
          plugin.summary(group).total_production_curve_for_consumer(node.key)
        else
          plugin.summary(group).total_production_curve_for_producer(node.key)
        end
      end

      # Public: A curve describing the demand in MWh of/for a specific consumer
      # or producer within Fever
      #
      # Returns an array
      def FEVER_DEMAND_CURVE(node)
        return [] unless Qernel::Plugins::Causality.enabled?(scope.graph)

        node = node.first
        return [] unless node.fever

        plugin = scope.graph.plugin(:time_resolve).fever
        group = node.fever.group

        if node.fever.type == :consumer
          plugin.summary(group).total_demand_curve_for_consumer(node.key)
        else
          plugin.summary(group).total_demand_curve_for_producer(node.key)
        end
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

      # Public: Loads a curve from the dataset by key.
      #
      # For example:
      #   DATASET_CURVE('weather/air_temperature')  # => [12.5, 12.3, 12.1, ...]
      #   DATASET_CURVE('total_demand')             # => [1250.0, 1300.0, ...]
      #
      # The key can be:
      #   - A curve set path: 'weather/air_temperature', 'solar/pv'
      #   - A simple profile name: 'total_demand', 'buildings_heating'
      #   - A user-attached curve (if configured)
      #
      # Returns an array of 8760 numeric values.
      def DATASET_CURVE(key)
        curves = Qernel::Causality::Curves.new(scope.graph, rotate: 0)
        curves.curve(key, nil).to_a
      end

      # Returns an attribute {Qernel::Emissions} or {Qernel::Emissions::ScopedSector} or a value.
      #
      # Emissions data is loaded from CSV files in ETSource with the following structure:
      #   etm_sector, etm_subsector, use, ghg, unit, value
      #
      # Parameters:
      #   - sector: ETM sector name (e.g., 'households', 'buildings_non_specified')
      #             Dashes/dots in sector names are converted to underscores for key generation
      #   - use: Emission use type (energetic, non_energetic) - REQUIRED when accessing values
      #   - ghg: GHG type (co2, other_ghg) - optional
      #   - year: Year of emission (e.g., 1990) - optional, reads from emissions_YEAR.csv files
      #
      # Key generation combines: sector_[subsector_]use_ghg[_year]
      # Note: Unit column from CSV is not included in keys, blank values return nil
      #
      # EMISSIONS() without any keys returns {Qernel::Emissions}
      #
      #   EMISSIONS() # => <Qernel::Emissions>
      #
      # EMISSIONS(sector, use) returns {Qernel::Emissions::ScopedSector}
      #
      # Which can be used to update emission factors:
      #   UPDATE(EMISSIONS(households, energetic), co2, VALUE )
      #   UPDATE(EMISSIONS(buildings_non_specified, energetic), other_ghg, VALUE )
      #
      # Examples
      #
      #   EMISSIONS(buildings_non_specified, energetic)
      #   # => <Qernel::Emissions::ScopedSector buildings_non_specified_energetic>
      #
      # EMISSIONS(sector, use, ghg) or EMISSIONS(sector, use, ghg, year) returns an emission value
      #
      # Examples
      #   EMISSIONS(households, energetic, other_ghg) # => 12.0 (from emissions.csv)
      #   EMISSIONS(households, energetic, co2) # => aggregated value (sum of subsectors, default year)
      #   EMISSIONS(households, energetic, co2, 1990) # => aggregated value for 1990
      #   EMISSIONS(buildings_non_specified, energetic, other_ghg, 2023) # => 18.0
      #
      def EMISSIONS(*keys)
        return scope.graph.emissions if keys.empty?

        # Convert dashes/dots to underscores in the first key (sector)
        keys[0] = keys.first.to_s.tr('-.', '_').to_sym

        # EMISSIONS(sector, use) -> return ScopedSector for UPDATE operations
        return scope.graph.emissions.scope(keys.join('_').to_sym) if keys.size == 2

        # EMISSIONS(sector, use, ghg [, year]) -> aggregate and return value
        scope.graph.emissions.sum(*keys)
      end

      # Returns an Array of {Qernel::Node} matching a CRT/IPCC code.
      #
      # Looks up the CRT code in the generic crt_mapping.csv file to find the
      # corresponding ETM sector, subsector, and use. Then returns all nodes
      # (from both energy and molecule graphs) that match those attributes.
      #
      # No crt_code attribute is needed on nodes - matching is inferred from
      # the mapping based on node sector, key (containing subsector), and use.
      #
      # crt_code - String or Symbol CRT code (e.g., '1.A.2', '2.B.10.a')
      #
      # Examples
      #
      #   EMISSIONS_MAP('1.A.4.a')
      #   # => [<Node>, <Node>, ...]
      #
      #   SUM(V(EMISSIONS_MAP('1.A.4.a'), demand))
      #   # => Sum demand from all nodes matching CRT code 1.A.4.a
      #
      #   UPDATE(EMISSIONS_MAP('1.A.4.a'), some_attribute, value)
      #   # => Update all matching nodes
      #
      # Returns an Array of Qernel::Nodes, or empty array if no mapping found.
      def EMISSIONS_MAP(crt_code)
        normalized_code = normalize_crt_code(crt_code)
        mapping = load_crt_mapping(normalized_code)

        return [] unless mapping

        find_nodes_by_mapping(mapping)
      end

      private

      # Internal: Normalizes a string for key matching.
      # Converts to lowercase, replaces spaces/hyphens with underscores.
      #
      # Returns a String.
      def normalize_key(str)
        str.to_s.downcase.tr(' -', '_')
      end

      # Internal: Normalizes CRT code for lookup.
      # Converts dots/hyphens to underscores, lowercase.
      #
      # Returns a Symbol.
      def normalize_crt_code(code)
        code.to_s.downcase.tr('-.', '_').to_sym
      end

      # Internal: Loads CRT mapping from dataset.
      #
      # Returns a CSV::Row or nil.
      def load_crt_mapping(normalized_code)
        dataset = Atlas::Dataset.find(scope.graph.area.area_code)
        dataset.crt_mapping[normalized_code]
      end

      # Internal: Finds all nodes matching the CRT mapping.
      #
      # Returns an Array of Qernel::Nodes.
      def find_nodes_by_mapping(mapping)
        sector = normalize_key(mapping[:etm_sector])
        subsector = normalize_key(mapping[:etm_subsector])
        use = normalize_key(mapping[:use])

        all_nodes.select { |node| node_matches_mapping?(node, sector, subsector, use) }
      end

      # Internal: Returns all nodes from both graphs.
      #
      # Returns an Array of Qernel::Nodes.
      def all_nodes
        scope.all_energy_nodes + scope.all_molecule_nodes
      end

      # Internal: Checks if a node matches the mapping criteria.
      #
      # Returns Boolean.
      def node_matches_mapping?(node, sector, subsector, use)
        return false unless node.sector_key.to_s == sector
        return false unless subsector_matches?(node, subsector)
        return false unless node.use_key.to_s == use

        true
      end

      # Internal: Checks if subsector matches node key.
      # Expects the subsector to be included in the node key.
      #
      # Returns Boolean.
      def subsector_matches?(node, subsector)
        node.key.to_s.include?(subsector)
      end
    end
  end
end
