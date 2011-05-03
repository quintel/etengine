module Qernel

#
# a converter can belong to multiple groups.
# groups are used to group similar converters together for easier querying.
#
class Group
  attr_accessor :id, :key

  def initialize(id,key)
    self.id = id
    self.key = key.to_sym
  end

end

end
