module Qernel::RecursiveFactor::Base


  # WARNING: This method should only be used for attributes unrelated to demand
  # See the exceptions in the code for why.
  #
  def recursive_factor_without_losses(strategy_method, converter_share_method = nil, link = nil, *args)
    if (return_value = send(strategy_method, link, *args)) != nil
      return_value
    else
      val = input_links.map do |link|
        child = link.rgt_converter
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

        if link_share == 0.0
          0.0 # just return 0.0 without doing complicated stuff below
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
          inp = self.input(link.carrier)
          child_conversion = (inp and inp.conversion) || 1.0
          child_value = child.recursive_factor_without_losses(strategy_method, converter_share_method, link, *args)

          link_share * child_value * child_conversion
        end
      end
      val.sum
    end
  end

  ##
  # The recursive_factor recursively traverses the graph from "self" (this converter) to the right.
  # It does so by following its input_links according to a *strategy method*. The strategy
  # method returns either:
  # * a 'weight' of a link/path. When returning a weight, the recursive_factor stops for that path
  # * nil, in which case the recursion continuess.
  #
  # Example:
  #   .4  b
  # a -<
  #   .6  c -- d (1.5)
  #   recursive_factor(:primary_demand_factor)
  #   1.) path b) b.primary_demand_factor => 0.4 * 1.0
  #   2.1.) d.primary_demand_factor => 1.0 * 1.5
  #   2.2.) c.primary_demand_factor => 0.6 * 1.5 (1.5 is result from 2.1)
  #   => (0.4*1.0) + (0.6*1.5)
  #
  #
  # @param strategy_method [String,Symbol] The method name that controls the flow
  # @param converter_share_method [String,Symbol] Additional method_name that gives a weight to a converter.
  #   E.g. we use #co2_free_factor to exclude converters that have co2 filters.
  # @param link [Qernel::Link] The link through which we called the recursive_factor (is nil for the first converter)
  # @param args Additional arguments
  # @return [Float] The factor with which we have to multiply. (E.g. demand * primary_demand_factor = primary_demand)
  #
  def recursive_factor(strategy_method, converter_share_method = nil, link = nil, *args)
    if (return_value = send(strategy_method, link, *args)) != nil
      return_value
    else
      val = input_links.map do |link|
        child = link.rgt_converter

        demanding_share = demanding_share(link)
        loss_share      = child.loss_share
        converter_share = converter_share_method.nil? ? 1.0 : (self.send(converter_share_method) || 0.0)

        if demanding_share == 0.0 or loss_share == 0.0 or converter_share == 0.0
          0.0
        else
          child_value = child.recursive_factor(strategy_method, converter_share_method, link, *args)
          demanding_share * loss_share * converter_share * child_value
        end
      end
      val.sum
    end
  end


  # Methods called at the final (most-right) converter.
  #
  # @return [Numeric]
  # @return [nil] if not defined and should continue to dance
  #
  def right_dead_end?
    unless defined?(@right_dead_end)
      @right_dead_end = self.input_links.reject{|l| l.rgt_converter.sector_environment? }.empty? # and !environment? # is already checked
    end
    @right_dead_end
  end


  def loss_share
    fetch_and_rescue(:loss_share) do
      v = self.share_of_losses
      (v == 1.0) ? 0.0 : (1.0 / (1.0 - self.share_of_losses))
    end
  end

  # Share of loss regarding total energy demand
  #
  def share_of_losses
    # theoretically should be the uncommented solution.
    # Takes into account the "flexible" losses, like grid losses
    #output_conversion?(:loss) ? output_conversion(:loss) : loss_per_demand
    loss_output_conversion
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
    # link.dataset_fetch(:demanding_share) do
      demanding_share = (link.value || 0.0) / (self.demand || 0.0)
      demanding_share = 0.0 if demanding_share.nan? or demanding_share.infinite?
      demanding_share
    # end
  end


end
