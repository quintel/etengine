
##
# This module is supposed to be included in {Qernel::Converter}.
# Core of the module is the wouter_dance, which is an algorithm that
# traverses from one converter to the right. To the right means it
# goes from the starting converter towards the input/input_links.
# Typically we need it to calculate primary_demands of a set of converter
# (be it total primary demand or sustainable primary demand). It can
# also be used for all different sorts of traversing.
#
# The wouter_dance consists of the following parts:
#
#
# == Adding new methods here
#
# When creating a new method that uses the wouter dance you have to:
#
# ==== 1. Create the method with the desired name
#
#   def sustainability_share
#     wouter_dance_without_losses(:sustainability_share_factor)
#   end
#
# To memoize results use the dataset_fetch method
#
#    def sustainability_share
#      dataset_fetch(:sustainability_share_factor_mem) do
#        wouter_dance_without_losses(:sustainability_share_factor)
#      end
#    end
#  
# ==== 2. Create a _factor method
# 
# The _factor method which returns either nil or a value.
# Returning nil, tells the wouter_dance to continue the recursiion
# (in the right direction) until it hits a value.
#
#   def carrier_cost_per_mj_factor(link)
#
# ==== 3. Create a proxy method in converter api
#
# Because Gqueries only access {ConverterApi} objects you either
# have to add a proxy method in that class or add a method_missing
# rule (not recommended because it's slow). 
#
#
#         -- 0.4 -- B (0.85)
# A(?) --|
#         -- 0.6 -- C (1.0)
#
#
module Qernel::Converter::PrimaryDemand
  ##
  # The share of sustainable energy. It is the (recursive) sum of the
  #  sustainable shares of its parents (nodes to the right).
  #
  # A.sustainability_share == 0.4*0.85 + 0.6 * 1.0
  #
  #
  #
  def sustainability_share
    dataset_fetch(:sustainability_share_factor_memoized) do
      wouter_dance_without_losses(:sustainability_share_factor)
    end
  end

  def sustainability_share_factor(link)
    if right_dead_end? and link
      link.carrier.sustainable
    else
      nil
    end
  end

  ##
  # Carrier Cost can depend on the share of other carriers flowing
  # into it. 
  # E.g. Gas price is dependent on the mix of greengas and natural 
  # gas. 
  #
  # A.carrier_cost_per_mj == 0.4*0.85 + 0.6 * 1.0
  #
  #
  #
  def weighted_carrier_cost_per_mj
    dataset_fetch(:weighted_carrier_cost_per_mj_memoized) do
      wouter_dance_without_losses(:weighted_carrier_cost_per_mj_factor)
    end
  end

  def weighted_carrier_cost_per_mj_factor(link)
    ##
    # because electricity and steam_hot_water are calculated seperatly these are excluded from this calculation
    # old: if right_dead_end? and link
    # new: always 0 for elec and steam_hw
    if link
      if (link.carrier.electricity? || link.carrier.steam_hot_water?)
        0.0
      else
        right_dead_end? ? link.carrier.cost_per_mj : nil
      end
    else
      nil
    end
  end

  ##
  # Same as weighted_carrier_cost_per_mj but for co2
  #
  def weighted_carrier_co2_per_mj
    dataset_fetch(:weighted_carrier_co2_per_mj_memoized) do
      wouter_dance_without_losses(:weighted_carrier_co2_per_mj_factor)
    end
  end

  def weighted_carrier_co2_per_mj_factor(link)
    if right_dead_end? and link
      link.carrier.co2_conversion_per_mj
    else
      nil
    end
  end

  # WARNING: This method should only be used for attributes unrelated to demand
  # See the exceptions in the code for why.
  #
  def wouter_dance_without_losses(strategy_method, converter_share_method = nil, link = nil, *args)
    if (return_value = send(strategy_method, link, *args)) != nil
      return_value
    else
      valid_links = self.input_links.reject{|l| l.child.environment? }
      val = valid_links.map do |link|
        child = link.child
        # Exception 1:
        # when import and local production of a carrier is 0 we still need a share of 1, 
        # otherwise the costs for fuel will always be 0.
        #
        # Exception 2:
        # If the demand for a converter is zero, certain links are assigned a nil share.
        # If a slot has two links with nil share, we have to assign shares, so they sum
        # up to 1.0 (and not 2.0, if we just did link.share || 1.0, to fix exception 1).
        # Therefore we assign averages, just to make this calculation work.
        #
        #                         --- link (constant: share nil) --- c_2 (method: 1.0)
        # slot(conversin: 1.0) <
        #                         --- link (flexible: share nil) --- c_3 (method: 1.0)
        # 
        # (1.0 * 1.0 * 1.0) + (1.0 * 1.0 * 1.0)  # (conversion * link_share * value)
        # => 2.0!
        #
        # => This has been changed in Link:
        #      - flexible are assigned share of 1.0 if nil
        #      - constant are assigned share of 0.0 if nil
        #
        link_share = link.share
        if link_share.nil?
          # Following code would make sure that combined link_shares would not 
          # be higher than 1.0:
          # total_link_shares = valid_links.map(&:share).compact.sum
          # link_share = (1.0 - total_link_shares) / valid_links.length
          link_share = 1.0
        end
        if link_share == 0.0 # or link_share.nil? # uncomment if not already checked above.
          0.0
        else
          # we have to multiply the share with the conversion of the corresponding slot
          # to deal with following scenario:
          #
          #       o slot(conversin: 0.9) --- link (share 1.0) --- c_2 (method: 100)
          # c_1 < 
          #       o slot(conversin: 0.1) --- link (share 1.0) --- c_3 (method: 80)
          # 
          # c_1 should then be: (0.9 * 1.0 * 100) + (0.1 * 1.0 * 80)
          #
          child_conversion = self.input(link.carrier).andand.conversion || 1.0
          child_value = child.wouter_dance_without_losses(strategy_method, converter_share_method, link, *args)

          # puts("#{self.id}) val: #{child_value}, conv: #{child_conversion}, share: #{link_share}")

          link_share * child_value * child_conversion
        end
      end
      val.sum
    end
  end


  ##
  # Calculates the primary energy demand. It recursively iterates through all the child links.
  #
  # primary_demand: demand * SUM(links)[ link_share * 1/(1-share_of_loss) * primary_demand_link]
  #
  # It uses primary_energy_demand? to determine if primary or not.
  #
  def primary_demand
    dataset_fetch(:primary_demand_memoized) do
      primary_demand_share = wouter_dance(:primary_demand_factor)
      (self.demand || 0.0) * (primary_demand_share)
    end
  end

  ##
  # Primary demand of only a specific carrier.
  #
  def primary_demand_of_carrier(carrier_key)
    factor = wouter_dance(:primary_demand_factor_of_carrier, nil, nil, carrier_key)
    (self.demand || 0.0) * factor
  end

  ##
  # Primary demand of sustainable sources. Uses the Carrier#sustainable attribute
  #
  def primary_demand_of_sustainable
    dataset_fetch(:primary_demand_of_sustainable_memoized) do
      (self.demand || 0.0) * (wouter_dance(:sustainable_factor))
    end
  end

  ##
  # Primary demand of fossil sources. (primary_demand - primary_demand_of_sustainable)
  #
  def primary_demand_of_fossil
    dataset_fetch(:primary_demand_of_fossil_memoized) do
      self.primary_demand - (wouter_dance(:sustainable_factor)) * (self.demand || 0.0)
    end
  end

  def primary_co2_emission
    dataset_fetch(:primary_co2_emission_memoized) do
      primary_demand_with(:co2_per_mj, :co2_free)
    end
  end

  def infinite_demand
    infinte_demand_factor ||= wouter_dance(:infinte_demand_factor)
    (self.demand || 0.0) * infinte_demand_factor
  end

  def final_demand
    dataset_fetch(:final_demand_memoized) do
      (self.demand || 0.0) * wouter_dance(:final_demand_factor)
    end
  end

  def final_demand_of_carrier(carrier_key)
    factor = wouter_dance(:final_demand_factor_of_carrier, nil, nil, carrier_key)
    (self.demand || 0.0) * factor
  end

  ##
  #
  #
  def primary_demand_co2_per_mj_of_carrier(carrier_key)
    factor = wouter_dance(:co2_per_mj_of_carrier_factor, nil, nil, carrier_key)
    (self.demand || 0.0) * factor
  end


  ##
  #
  #
  def primary_demand_with(factor_method, converter_share_method = nil)
    if converter_share_method
      w = wouter_dance("#{factor_method}_factor", "#{converter_share_method}_factor")
    else
      w = wouter_dance("#{factor_method}_factor")
    end
    d = (self.demand || 0.0)
    w * d
  end

  ##
  # The wouter_dance recursively traverses the graph from "self" (this converter) to the right.
  # It does so by following its input_links according to a *strategy method*. The strategy
  # method returns either:
  # * a 'weight' of a link/path. When returning a weight, the wouter_dance stops for that path
  # * nil, in which case the recursion continuess.
  #
  # Example:
  #   .4  b
  # a -<
  #   .6  c -- d (1.5)
  #   wouter_dance(:primary_demand_factor)
  #   1.) path b) b.primary_demand_factor => 0.4 * 1.0
  #   2.1.) d.primary_demand_factor => 1.0 * 1.5
  #   2.2.) c.primary_demand_factor => 0.6 * 1.5 (1.5 is result from 2.1)
  #   => (0.4*1.0) + (0.6*1.5)
  #
  #
  # @param strategy_method [String,Symbol] The method name that controls the flow
  # @param converter_share_method [String,Symbol] Additional method_name that gives a weight to a converter.
  #   E.g. we use #co2_free_factor to exclude converters that have co2 filters.
  # @param link [Qernel::Link] The link through which we called the wouter_dance (is nil for the first converter)
  # @param args Additional arguments
  # @return [Float] The factor with which we have to multiply. (E.g. demand * primary_demand_factor = primary_demand)
  #
  def wouter_dance(strategy_method, converter_share_method = nil, link = nil, *args)
    if (return_value = send(strategy_method, link, *args)) != nil
      return_value
    else
      val = self.input_links.reject{|l| l.child.environment? }.map do |link|
        child = link.child

        demanding_share = demanding_share(link)
        loss_share = child.loss_share
        converter_share = converter_share_method.nil? ? 1.0 : (self.send(converter_share_method) || 0.0)

        if demanding_share == 0.0 or loss_share == 0.0 or converter_share == 0.0
          0.0
        else
          child_value = child.wouter_dance(strategy_method, converter_share_method, link, *args)
          demanding_share * loss_share * converter_share * child_value
        end
      end
      val.sum
    end
  end

  ##
  #
  #
  def loss_share
    # TODO optimize by using dataset_fetch
    v = self.share_of_losses
    (v == 1.0) ? 0.0 : (1.0 / (1.0 - self.share_of_losses))
  end

  ##
  # In contrast to link.share, demanding_share takes also into account
  # losses and zero-demands. E.g.
  #
  # -- link_1 share 0.1 ---------\
  # -- link_2 share 0.8 ----------- c_1 (0 demand)
  # -- link_3 share 0.1 (loss) --/
  #
  # link_2.share => 0.8
  # demanding_share(link_2) => 0.0
  # demanding_share(link_3) => 0.0 (always!)
  #
  def demanding_share(link)
    # TODO optimize by using dataset_fetch
    return 0.0 if link.loss?
    demanding_share = (link.value || 0.0) / (self.demand || 0.0)
    demanding_share = 0.0 if demanding_share.nan? or demanding_share.infinite?
    demanding_share
  end

  ##
  # Total amount of energy that are losses
  #
  # @return [Float]
  #
  def total_losses
    out = self.output(:loss)
    out and out.external_value
  end

  ##
  # Share of loss regarding total energy demand
  #
  # @return [Float]
  #
  def share_of_losses
    # theoretically should be the uncommented solution.
    # Takes into account the "flexible" losses, like grid losses
    #output_conversion?(:loss) ? output_conversion(:loss) : loss_per_demand
    loss_output_conversion
  end

  ###
  # Methods called at the final (most-right) converter.
  #
  #
  # @return [Numeric]
  # @return [nil] if not defined and should continue to dance
  #
  def right_dead_end?
    unless defined?(@right_dead_end)
      @right_dead_end = self.input_links.reject{|l| l.child.sector_environment? }.empty? # and !environment? # is already checked
    end
    @right_dead_end
  end

  def final_demand_factor_of_carrier(link, carrier_key, ruby18fix = nil)
#    link ||= output_links.first
#
#    return nil if !right_dead_end? or !primary_energy_demand?
#
#    if carrier = link.andand.carrier and carrier.key == carrier_key
#      return 1.0 if final_demand_cbs?
#    end
#
#    return 0.0
  end

  def infinite?
    carriers = slots.map {|slot| slot.carrier}.uniq
    !carriers.empty? and carriers.any?{|carrier| carrier.infinite == 1.0}
  end

  def infinte_demand_factor(link,ruby18fix = nil)
    return nil if !right_dead_end?
    (infinite? and primary_energy_demand?) ? (1 - loss_output_conversion) : 0.0
  end

  def primary_demand_factor(link,ruby18fix = nil)
    return nil if !right_dead_end? # or !primary_energy_demand?
    # We return nil when we want to continue traversing. So typically this is until
    # we hit a dead end. Alternatively (for final_demand) we could stop when we hit
    # a converter that is final_demand_cbs?
    factor_for_primary_demand(link)
  end


  def primary_demand_factor_of_carrier(link, carrier_key, ruby18fix = nil)
    return nil if !right_dead_end? or !primary_energy_demand?
    link ||= output_links.first

    if link and link.carrier.key == carrier_key
      factor_for_primary_demand(link)
    else
      0.0
    end
  end

  def factor_for_primary_demand(link)
    # Example of a case when a link is not assigned (and therefore needs to be assigned
    # in order to check if its imported_electricity):
    # When you get the primary_demand of the group primary_energy_demand, you already
    # start at the right dead end and don't jump throught links.
    link ||= output_links.first

    # If a converter has infinite ressources (such as wind, solar/sun), we
    # take the output of energy (1 - losses).
    if infinite? and primary_energy_demand?
      (1 - loss_output_conversion)

    # Special case is imported electricity, if we import, somebody else has
    # to produce that electricity from primary energy. To take that into account
    # we add a higher factor for imported_electricity.
    elsif primary_energy_demand? and link and link.carrier.key === :imported_electricity
      # if export should be 1, if its import should be 1.82
      if demand > 0.0 # if demand greater then 0.0 electricity is imported
        graph.area.import_electricity_primary_demand_factor
      else # energy gets exported.
        graph.area.export_electricity_primary_demand_factor
      end

    elsif primary_energy_demand? # Normal case.
      1.0
    # ignore this converter if it is a dead end but not a primary_energy_demand.
    # for example some environment converters.
    else
      0.0
    end
  end


  def co2_free_factor
    (1.0 - (query.co2_free || 0.0))
  end

  ##
  #
  # @return [0.0] if converter is non_energetic_use / has co2_free of 1.0. This ends the wouter_dance.
  # @return [nil] until dead end or primary_energy_demand
  # @return [Float] co2_per_mj of primary_energy_demand carrier
  #
  def co2_per_mj_of_carrier_factor(link, carrier_key, ruby18fix = nil)
    return 0.0 if query.co2_free == 1.0
    return nil if !right_dead_end? or !primary_energy_demand?
    link ||= output_links.first

    if link and carrier = link.carrier and link.carrier.key == carrier_key
      return 0.0 if query.co2_free.nil? or carrier.co2_conversion_per_mj.nil?
      carrier.co2_per_mj - (query.co2_free * carrier.co2_conversion_per_mj)
    else
      0.0
    end
  end

  ##
  #
  # @return [0.0] if converter is non_energetic_use / has co2_free of 1.0. This ends the wouter_dance.
  # @return [nil] until dead end or primary_energy_demand
  # @return [Float] co2_per_mj of primary_energy_demand carrier
  #
  def co2_per_mj_factor(link,ruby18fix = nil)
    #return 0.0 if query.co2_free == 1.0
    return nil if !right_dead_end? or !primary_energy_demand?
    link ||= output_links.first

    carrier = link.nil? ? output_carriers.reject(&:loss?).first : link.carrier
    puts "no carrier for #{self.name}" if carrier.nil?

    return 0.0 if query.co2_free.nil? or carrier.co2_conversion_per_mj.nil?
    co2_ex_free = carrier.co2_per_mj - (query.co2_free * carrier.co2_conversion_per_mj)
    (primary_energy_demand? and carrier.co2_conversion_per_mj) ? co2_ex_free : 0.0
  end



  #def sustainable_factor(link,ruby18fix = nil)
  #  return nil unless right_dead_end?
  #  link ||= output_links.first
  #
  #    link.nil? ? 0.0 : link.carrier.sustainable
  # end

  def sustainable_factor(link,ruby18fix = nil)
    return nil if !right_dead_end?
    link ||= output_links.first

    if infinite? and primary_energy_demand?
      (1 - loss_output_conversion)
    elsif primary_energy_demand? and link and link.carrier.sustainable
      link.carrier.sustainable
    else
      0.0
    end
  end

  def final_demand_factor(link,ruby18fix = nil)
    return 1.0 if final_demand_cbs?
    return 0.0 if right_dead_end?
    nil
  end

end
