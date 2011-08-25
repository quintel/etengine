module Gql::UpdateInterface
  
  COMMAND_TYPES = [
    #SlotConversionCommand, 
    ConverterSlotsCommand,
    MultiCommandFactory,
    AttributeCommand,
    MarketShareCarrierCommand, # has to be before MarketShareCommand, as it is a more specific case.
    MarketShareCommand,
    LinkShareCommand    
  ]

  ## 
  # CommandFactory returns the correct Command-object based on the key.
  #
  class CommandFactory

    ##
    # Derives correct CommandBase Factory based on key. 
    # Returns an instance(s) of the concrete Factory.
    #
    # @param graph [Qernel::Graph]
    # @param converter_proxy [Qernel::ConverterApi]
    # @param key [String]
    # @param value [Float]
    #
    # @return [CommandBase]
    #
    def self.create(graph, converter_proxy, key, value)
      klass = COMMAND_TYPES.detect do |klass|
        klass.responsible?(key)
      end
      klass.nil? ? nil : klass.create(graph, converter_proxy, key, value)
    end

  end
end