module Gql::UpdateInterface
##
# Updates a link share of a converter.
# Limitiations:
# - Currently can only update 1 link share, so if multiple links
#   are matched, we might have a situation.
#
class SlotConversionCommand < CommandBase
  include HasConverter
  include ResponsibleByMatcher

  # <carrier_key>_<input|output>_link_share
  # e.g. electricity_output_link_share
  MATCHER = /^(.*)_(input|output)_slot_conversion$/

  

  def execute
    if @attr_name.match(MATCHER) == nil
      raise "#{converter.full_key} #{@attr_name} not matching"
    end
    carrier_name, inout = @attr_name.match(MATCHER).captures

    if carrier_name and slot = converter.send(inout, carrier_name.to_sym)
      slot.conversion = value
      #slots = @object.send(inout.pluralize) # (inputs or outputs)
      #if remaining_slot = (slots - [slot]).first
      #  remaining_slot.conversion = 1.0 - value
      #end
    end
  end

  def value
    @command_value
  end
  
  def self.create(graph, converter_proxy, key, value)
    new(converter_proxy, key, value)
  end

end

end
