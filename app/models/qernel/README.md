### max_demand

Issue: https://github.com/dennisschoenmakers/etsource/issues/77
Issue: https://github.com/dennisschoenmakers/etengine/issues/332

max_demand is a dataset attribute and can be defined on a converter or on a link. 

Link#max_demand will either take the link[:max_demand] or if undefined the max_demand of the converter to the right.


### max_demand_recursive

Issue: https://github.com/dennisschoenmakers/etengine/issues/331
Implemented in: app/models/qernel/recursive_factor/max_demand.rb

It uses the recursive_factor to calculate it's value.



                 