# frozen_string_literal: true

module GraphDataValidation
  class NodeGroup
    include Enumerable

    # period can be present or future
    # graph for now is just energy! We can easily expand to molecules by including:
    # group_molecule_nodes(group_key)
    def initialize(group_key, gql, period: :present)
      @nodes = gql.public_send(period).group_energy_nodes(group_key)
    end

    def each(&block)
      @nodes.each do |node|
        yield node.node_api
      end
    end
  end
end

