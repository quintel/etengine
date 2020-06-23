module Etsource
  # Loads data for a dataset defined in ETSource.
  #
  # Note: Occurrences of `(some number) * 1_000_000`` are due to energy demands
  # in the Atlas+Refinery data being expressed in PJ, while ETEngine uses MJ.
  class Dataset::Import
    attr_reader :country

    # Public: The loader used to create and fetch Atlas::ProductionMode
    # instances.
    #
    # Returns an AtlasLoader::PreCalculated or AtlasLoader::Lazy.
    def self.loader
      # We have to set a default loader when it is nil, since Rails deletes
      # the values of class variables when reloading code.
      @loader ||=
        if APP_CONFIG[:etsource_lazy_load_dataset]
          AtlasLoader::Lazy.new(Rails.root.join('tmp/atlas'))
        else
          AtlasLoader::PreCalculated.new(Rails.root.join('tmp/atlas'))
        end
    end

    # Public: Sets which loader (PreCalculated or Lazy) is to be used to fetch
    # Atlas ProductionMode instances.
    #
    # Returns the loader.
    def self.loader=(loader)
      @loader = loader
    end

    def initialize(country)
      @country  = country
      @dataset  = Qernel::Dataset.new(Hashpipe.hash(country))
      @atlas_ds = Atlas::Dataset.find(@country)
    end

    # Public: Imports dataset information with the given dataset hash.
    #
    # Returns a Qernel::Dataset.
    def import_data(data)
      @dataset.data = data
      @dataset.data[:graph][:graph] = { calculated: false }

      @dataset
    end

    # Public: Imports dataset information.
    #
    # Returns a Qernel::Dataset.
    def import
      import_data(load_dataset_hash)
    end

    # Return all the carrier keys we have defined in the dataset.
    # (used to dynamically generate some methods)
    #
    # Returns an array of symbols.
    def carrier_keys
      Atlas::Carrier.all.map(&:key)
    end

    def raw_hash
      load_dataset_hash({})
    end

    protected

    def load_dataset_hash
      { area:        load_region_data,
        carriers:    load_carrier_data,
        graph:       load_graph_dataset,
        time_curves: load_time_curves }
    end

    # Internal: Reads the shares, demands, and other regional data from the
    # production-mode Atlas documents, populating the +:graph+ part of the
    # dataset.
    #
    # Returns a hash containing the data.
    def load_graph_dataset
      graph_dataset = {}

      graph_objects = self.class.loader.load(@country)

      graph_objects.nodes.each { |node| import_node!(node, graph_dataset) }
      graph_objects.edges.each { |edge| import_edge!(edge, graph_dataset) }

      graph_dataset
    end

    # Internal: Loads the region data.
    #
    # Returns a hash.
    def load_region_data
      { area_data: @atlas_ds.to_hash }
    end

    # Internal: Loads the carrier data.
    #
    # Returns a hash, each key-pair being a carrier.
    def load_carrier_data
      Atlas::Carrier.all.each_with_object({}) do |carrier, data|
        data[carrier.key] = carrier.to_hash
      end
    end

    # Internal: Loads time curve data via the Atlas CSVs.
    #
    # Returns a hash where each key is the key for a node, and the values are
    # hashes containing attributes and values.
    def load_time_curves
      @atlas_ds.time_curves.each_with_object({}) do |(key, csv), data|
        headers = csv.table.headers - [:year]
        curves  = {}

        data[key] = csv.table.each do |row|
          headers.each do |header|
            curves[header] ||= {}
            curves[header][row[:year]] = row[header].to_f * 1_000_000
          end
        end

        data[key] = curves
      end
    end

    # Internal: Given an Atlas node, determines if that node should have a
    # useful demand attribute, or an expected demand attribute.
    #
    # Returns true or false.
    def demand_attribute(node)
      if Atlas::Node.find(node.key).groups.include?(:preset_demand)
        :preset_demand
      else
        :demand_expected_value
      end
    end

    # Internal: Converts the attributes from a production-mode Atlas node and
    # sets the relevant data onto the ETEngine :graph dataset.
    #
    # Also imports slots.
    #
    # node    - The Atlas::Node.
    # dataset - The :graph part of the dataset.
    #
    # Returns nothing.
    def import_node!(node, dataset)
      attributes = node.attributes
      attributes.delete(:demand)

      if demand_attribute(node) == :preset_demand
        attributes[:preset_demand] = val(node, :demand) * 1_000_000
      elsif node.demand
        attributes[:demand_expected_value] = node.demand * 1_000_000
      end

      # Test that max_demand is numeric, since some old tests assign the value
      # to be "recursive".
      if attributes[:max_demand].is_a?(Numeric)
        attributes[:max_demand] *= 1_000_000
      end

      dataset[Hashpipe.hash(node.key)] = attributes

      (node.in_slots + node.out_slots).each do |slot|
        import_slot!(slot, dataset)
      end
    end

    # Internal: Converts the attributes from a production-mode Atlas slot and
    # sets the conversion and other relevant attributes onto the dataset.
    #
    # slot    - The Atlas::Slot.
    # dataset - The :graph part of the dataset.
    #
    # Returns nothing.
    def import_slot!(slot, dataset)
      key = FromAtlas.slot_key(slot.node.key, slot.carrier, slot.direction)
      attributes = {}

      unless slot.is_a?(Atlas::Slot::Elastic)
        attributes[:conversion] = val(slot, :share)
      end

      if slot.carrier == :coupling_carrier && slot.in?
        attributes[:reset_to_zero] = true
      end

      dataset[Hashpipe.hash(key)] = attributes
    end

    # Internal: Converts the attributes from a production-mode Atlas edge and
    # sets the attributes onto the dataset.
    #
    # edge    - The Atlas::Edge.
    # dataset - The :graph part of the dataset.
    #
    # Returns nothing.
    def import_edge!(edge, dataset)
      attributes = edge.attributes

      if edge.type == :share
        attributes[:share] =
          attributes[edge.reversed? ? :parent_share : :child_share]
      elsif edge.type == :constant
        attributes[:share] = attributes[:demand] * 1_000_000
      end

      attributes.delete(:child_share)
      attributes.delete(:parent_share)
      attributes.delete(:demand)

      dataset[Hashpipe.hash(FromAtlas.edge_key(edge))] = attributes
    end

    # Internal: Given a production-mode Atlas object and an attribute name,
    # returns the value of the attribute, or raises an error if it is nil.
    #
    # Returns the value.
    def val(document, attribute)
      document.public_send(attribute) ||
        raise("#{ document.inspect } has no #{ attribute.inspect } value")
    end
  end # Import
end # Etsource
