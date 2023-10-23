module Etsource
  class MeritOrder
    def initialize(etsource = Etsource::Base.instance)
      @etsource = etsource
    end

    # Public: reads the electricity merit order definitions from Atlas Node
    # data.
    #
    # See MeritOrder#import
    #
    # Returns a hash.
    def import_electricity
      import(:merit_order)
    end

    # Public: reads the heat network merit order definitions from Atlas Node
    # data.
    #
    # See MeritOrder#import
    #
    # Returns a hash.
    def import_heat_network_lt
      import(:heat_network_lt)
    end

    # Public: reads the heat network merit order definitions from Atlas Node
    # data.
    #
    # See MeritOrder#import
    #
    # Returns a hash.
    def import_heat_network_mt
      import(:heat_network_mt)
    end

    # Public: reads the heat network merit order definitions from Atlas Node
    # data.
    #
    # See MeritOrder#import
    #
    # Returns a hash.
    def import_heat_network_ht
      import(:heat_network_ht)
    end

    # Public: reads the agriculture heat merit order definitions from Atlas Node
    # data.
    #
    # See MeritOrder#import
    #
    # Returns a hash.
    def import_agriculture_heat
      import(:agriculture_heat)
    end

    private

    # Internal: Reads the merit order definitions from the Atlas nodes list.
    #
    # There are a few weird idiosyncrasies here; the method returns a hash
    # containing keys for each "type" of merit order node, where each value is
    # a hash. This nested hash contains keys for each merit order node, and the
    # "group" to which the node belongs.
    #
    # The "type" and "group" are cast to strings (from symbols) because that's
    # what other code expects.
    #
    # The hash looks like this:
    #
    #   { "dispatchable" => { "node_one" => nil,
    #                         "node_two" => "buildings_chp" },
    #     "volatile"     => { "node_three" => "solar_pv" } }
    #
    # Returns a hash.
    def import(attribute)
      Rails.cache.fetch("#{attribute}_hash") do
        mo_nodes = Atlas::EnergyNode.all.select(&attribute).sort_by(&:key)
        mo_data  = {}

        mo_nodes.each do |node|
          config = node.public_send(attribute)
          type   = config.type.to_s
          group  = config.group&.to_s

          mo_data[type] ||= {}
          mo_data[type][node.key.to_s] = group
        end

        mo_data
      end
    end
  end
end
