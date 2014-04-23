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
      elsif has_loop?
        nil
      else
        capped_link = rgt_links.min_by do |l|
          l.rgt_converter.max_demand_recursive! / l.share rescue Float::INFINITY
        end
        query.max_demand = capped_link.rgt_converter.max_demand_recursive! / capped_link.share rescue nil
      end
    end
  end
end
