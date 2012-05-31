module Qernel::WouterDance::MaxDemand
  def max_demand_recursive
    if query.max_demand
      query.max_demand
    else
      # the following line simply makes sure that converters recursively
      # calculate a max_demand.
      rgt_converters.each(&:max_demand_recursive) 
      # now we can sum the max_demands
      query.max_demand = rgt_links.map(&:max_demand).sum
    end
  end
end