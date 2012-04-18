module Rubel
  # Base is the runtime with builtin sandbox to make it hard to run malicious or undefined code.
  #
  # The sandbox is created by making Base a subclass from BasicObject which has two effects:
  # - BasicObject does not include Kernel (no methods like puts, system, ``, open, etc)
  # - BasicObject is outside of the standard namespace, so classes are only found with the :: prefix.
  #
  # Base overwrites method_missing and const_missing to simply return the name as a Symbol. 
  # This allows the query language to not require "", '' or : for things like lookup keys.
  # VALUE(foo, sqrt) vs VALUE("foo", "sqrt")
  # 
  class Base < BasicObject
    include Core
  end
end

# [1] this allows embedding GQL into attribute names, e.g.: 
#   V(foo, primary_demand_of(CARRIER(gas)))

