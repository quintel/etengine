module Gql::Update
##
# Updates a link share of a converter.
# Limitiations:
# - Currently can only update 1 link share, so if multiple links
#   are matched, we might have a situation.
#
class ConverterSlotsCommand < CommandBase
  include HasConverter
  include ResponsibleByMatcher

  # <carrier_key>_<input|output>_link_share
  # e.g. electricity_output_link_share
  MATCHER = /^(.*)_(input|output)_conversion_(growth_rate|conversion|value)$/


  def execute
    cmds.each(&:execute)
    cmds
  end

  def cmds
    cmds = []
    carrier_name, inout, type = @attr_name.match(MATCHER).captures
    type = 'value' if type == 'conversion'

    slots = converter.send(inout.pluralize)

    update_slot = converter.send(inout, carrier_name.to_sym)

    upd_cmd = AttributeCommand.new(update_slot, :conversion, value.to_f, type)
    cmds << upd_cmd

    # if remaining_slot = (slots - [update_slot]).first #and slots.length > 2
    #   cmds << AttributeCommand.new(remaining_slot, :conversion, 1.0 - upd_cmd.value, :value)
    # end

    cmds
  end

  def value
    @command_value
  end

  def self.create(graph, converter_proxy, key, value)
    new(converter_proxy, key, value)
  end

end

end
