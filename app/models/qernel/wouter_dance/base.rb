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
module Qernel::WouterDance::Base
  # WARNING: This method should only be used for attributes unrelated to demand
  # See the exceptions in the code for why.
  #
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
  #                        + --- link (constant: share nil) --- c_2 (method: 1.0)
  # slot(conversin: 1.0) - + --- link (flexible: share nil) --- c_3 (method: 1.0)
  # 
  # (1.0 * 1.0 * 1.0) + (1.0 * 1.0 * 1.0)  # (conversion * link_share * value)
  # => 2.0!
  #
  # => This has been changed in Link:
  #      - flexible are assigned share of 1.0 if nil
  #      - constant are assigned share of 0.0 if nil
  def wouter_dance_without_losses(strategy_method, converter_share_method = nil, start_link = nil, *args)
    if (return_value = send(strategy_method, start_link, *args)) != nil
      return_value
    else
      val = input_links.reject(&:to_environment?).map do |link|
        child      = link.child
        link_share = link.share || 1.0
        
        if link_share == 0.0 # or link_share.nil? # uncomment if not already checked above.
          0.0 
        else
          # we have to multiply the share with the conversion of the corresponding slot
          # to deal with following scenario:
          #
          #       +--o slot(conversin: 0.9) --- link (share 1.0) --- c_2 (method: 100)
          # c_1 --+--o slot(conversin: 0.1) --- link (share 1.0) --- c_3 (method: 80)
          # 
          # c_1 should then be: (0.9 * 1.0 * 100) + (0.1 * 1.0 * 80)
          input = input(link.carrier)
          child_conversion = (input and input.conversion) || 1.0

          right_value = protect_from_loop(link, strategy_method, true, *args) do
            child.wouter_dance_without_losses(strategy_method, converter_share_method, link, *args)
          end

          link_share * right_value * child_conversion
        end
      end
      val.sum
    end
  end


  # Protects a wouter_dance from loops in the graph.
  # It does so by setting a flag on the link with the strategy_method
  # as key. It also supports memoization of values.
  #
  def protect_from_loop(link, strategy_method, memoize_values = true, *args)
    # primary_demand_of_gas and primary_demand_of_oil have primary_demand_of
    # as strategy_method and "oil"/"gas" in args. Join the keys, to have unique
    # caching key for link. 
    cached_key = "#{strategy_method}_#{args}" if args.present?
    cached = link.dataset_get(cached_key)

    if cached == :loop_alert # We have a loop now. Define what should happen here.
      send(strategy_method, link, *args) || 1.0
    elsif memoize_values && cached.present? # this is simple memoization.
      cached
    else
      # flag this link with a :loop_alert, before we actually continue the recursion.
      link.dataset_set(cached_key, :loop_alert)
      # Start the recursion. if a loop happens, it will be caught in above if clause.
      val = yield
      # the following simply memoizes the result.
      link.dataset_set(cached_key, val) if memoize_values
      val
    end
  end



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
  def wouter_dance(strategy_method, converter_share_method = nil, start_link = nil, *args)
    # if the strategy_method returns a number, it means wouter_dance has
    # already been there. if nil, it has not been there: so calculate.
    if (return_value = send(strategy_method, start_link, *args)) != nil
      return_value
    else
      # Protect from loops:
      # 
      val = input_links.reject(&:to_environment?).map do |link|
        right_converter = link.child

        demanding_share = demanding_share(link)
        loss_share      = right_converter.loss_share
        converter_share = converter_share_method.nil? ? 1.0 : (self.send(converter_share_method) || 0.0)

        if demanding_share == 0.0 or loss_share == 0.0 or converter_share == 0.0
          0.0
        else
          right_value = protect_from_loop(link, strategy_method, true, *args) do
            right_converter.wouter_dance(strategy_method, converter_share_method, link, *args)
          end

          demanding_share * loss_share * converter_share * right_value
        end
      end
      val.sum
    end
  end

  
  def loss_share
    # TODO optimize by using dataset_fetch
    dataset_fetch(:loss_share) do
      v = self.share_of_losses
      (v == 1.0) ? 0.0 : (1.0 / (1.0 - self.share_of_losses))
    end
  end


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


  # Total amount of energy that are losses
  #
  def total_losses
    out = self.output(:loss)
    out and out.external_value
  end


  # Share of loss regarding total energy demand
  #
  def share_of_losses
    # theoretically should be the uncommented solution.
    # Takes into account the "flexible" losses, like grid losses
    #output_conversion?(:loss) ? output_conversion(:loss) : loss_per_demand
    loss_output_conversion
  end


  # Methods called at the final (most-right) converter.
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


  def infinite?
    carriers = slots.map{|slot| slot.carrier}.uniq
    !carriers.empty? and carriers.any?{|carrier| carrier.infinite == 1.0}
  end


end
