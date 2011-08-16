module Gql::UpdateInterface
##
# Updates a link share of a converter.
# Limitiations:
# - Currently can only update 1 link share, so if multiple links
#   are matched, we might have a situation.
#
#
class LinkShareCommand < CommandBase
  include HasConverter
  include ResponsibleByMatcher

  # <carrier_key>_(<constant|share>_)<input|output>_link_share
  # e.g.
  # electricity_output_link_share
                                            # HACK HACK HACK
  MATCHER = /^(.*)_(input|output)_link_share(_growth_rate)?$/

  # TODO refactor (seb 2010-10-11)
  def execute
    match = @attr_name.match(MATCHER)
    if match.nil?
      # HACK HACK HACK
      Rails.logger.warn('doesnt match')
      return nil
    end
    carrier_name, inout, is_growth_rate = match.captures


    if link_type = carrier_name[/^.*_(constant|share)$/,1]
      carrier_name = carrier_name[/^(.*)_(constant|share)$/, 1]
    end
    if carrier_name and slot = converter.send(inout, carrier_name.to_sym)
      links = link_type.nil? ? slot.links : slot.links.select(&:"#{link_type}?")
      if link = links.first
        if is_growth_rate.blank?
          link.share = value
        else
          # HACK HACK HACK
          link.share = (1.0 - (1.0 - value)**Current.scenario.years)
        end
      end
      if links.length > 1
        Rails.logger.warn("LinkShareCommand: multiple links exist for '#{@attr_name}'. But only one link share can be updated. Possible Error")
      end
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
