module Qernel::RecursiveFactor::MaxDemand
  def max_demand_recursive
    if query.max_demand
      query.max_demand
    else
      minimum_cap_link = rgt_links.min_by {|l| l.share * l.rgt_converter.max_demand_recursive rescue Float::INFINITY}
      query.max_demand = minimum_cap_link.rgt_converter.max_demand_recursive / minimum_cap_link.share rescue nil
    end
  end
end