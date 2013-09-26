module Etsource
  class MeritOrder
    def initialize(etsource = Etsource::Base.instance)
      @etsource = etsource
    end

    # Public: Reads the merit order definitions from the Atlas nodes list.
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
    def import
      Rails.cache.fetch('merit_order_hash') do
        mo_nodes = Atlas::Node.all.select(&:merit_order)
        mo_data  = {}

        mo_nodes.each do |node|
          type  = node.merit_order.type.to_s
          group = node.merit_order.group && node.merit_order.group.to_s

          mo_data[type] ||= {}
          mo_data[type][node.key.to_s] = group
        end

        mo_data
      end
    end
  end
end
