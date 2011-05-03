module Gql::Update
##
# Use this if a Command is updating a converter object.
# It assumes that the command-instance assigns the proxy 
# object (Qernel::ConverterApi) to @object
#
module HasConverter

  def converter_proxy
    #if self.object.is_a?(Qernel)
    self.object
  end

  def converter
    converter_proxy.converter
  end

end

end