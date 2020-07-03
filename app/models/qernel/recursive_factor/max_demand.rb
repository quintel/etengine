module Qernel::RecursiveFactor::MaxDemand
  # max_demand_recursive is calculated by the MaxDemandRecursive plugin.
  # This method has to be called explicitly.
  #
  # Note: this method overwrites the max_demand attribute!
  #
  def max_demand_recursive!
    fetch(:"max_demand_recursive!") do
      if query.max_demand && query.max_demand != 'recursive'
        query.max_demand
      elsif node.has_loop?
        nil
      else
        capped_edge =
          rgt_edges.min_by do |l|
            l.rgt_node.query.max_demand_recursive! / l.share
          rescue RuntimeError
            Float::INFINITY
          end

        query.max_demand =
          begin
            capped_edge.rgt_node.query.max_demand_recursive! / capped_edge.share
          rescue RuntimeError
            nil
          end
      end
    end
  end

  # Returns a numeric value in MJ.
  alias_method :max_demand_recursive, :max_demand_recursive!
end
