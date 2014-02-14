module Qernel::RecursiveFactor::Base

  # Public: Recursively traverses the graph from "self" (this converter) to
  # the parent (supplier) converters. It does so by following its input_links
  # according to a +strategy method+. The strategy method returns either:
  #
  #   * a 'weight' of a link/path. When returning a weight, the
  #     recursive_factor stops for that path
  #
  #   * nil, in which case the recursion continues.
  #
  # For example:
  #
  #   #        [B] (0.4)
  #   #        /
  #   # [A] <--
  #   #        \
  #   #        [C] (0.6) <-- [D] (1.5)
  #
  #   recursive_factor(:primary_demand_factor)
  #
  #   # 1.   B.primary_demand_factor => 0.4 * 1.0
  #   # 2.1. D.primary_demand_factor => 1.0 * 1.5
  #   # 2.2. C.primary_demand_factor => 0.6 * 1.5 (1.5 is result from 2.1)
  #   #
  #   # => (0.4 * 1.0) + (0.6 * 1.5)
  #
  # strategy_method        - The method name that controls the flow.
  #
  # converter_share_method - Additional method_name that gives a weight to a
  #                          converter. For example, use #co2_factor to
  #                          exclude converters that have co2 filters.
  #
  # link                   - The link through which we called the
  #                          recursive_factor (this is nil for the first
  #                          converter; recursive_factor uses it internally).
  #
  # *args                  - Additional arguments passed along to the strategy
  #                          method.
  #
  # Returns a float.
  def recursive_factor(strategy_method, converter_share_method = nil, link = nil, *args)
    if (return_value = send(strategy_method, link, *args)) != nil
      return_value
    else
      results = input_links.map do |link|
        parent = link.rgt_converter

        # The demanding_share returns the right-to-left share. This is the
        # same as +link.share+ except when the carrier is loss, in which case
        # the share will always be 0.0 since we include losses separately
        # using +loss_compensation_factor+.
        #
        # [A] <-- [B] (demanding_share = 100%)
        #      \- [C] (demanding_share = 100%)
        #
        # [A] needs to be 100% * [B] + 100% * [C]
        demanding_share = demanding_share(link)

        # The output of the parent needs to be multiplied by this
        # "compensation factor" to include losses.
        #
        # See https://github.com/quintel/etengine/issues/518.
        loss_compensation_factor = parent.loss_compensation_factor

        # What part is considered to be contributing to the outcome?
        # (e.g. 80% when free_co2_factor is 20%). This is 100% when the
        # converter_share method is nil.
        converter_share = converter_share(converter_share_method)

        if demanding_share.zero?
          # The converter has no demand, we can safely omit it.
          0.0
        elsif loss_compensation_factor.zero?
          # The converter is 100% loss, so there is no point in recursing
          # further on this link.
          0.0
        elsif converter_share.zero?
          # The converter has been assigned a weight of zero, so we can safely
          # omit it.
          0.0
        else
          parent_value = parent.recursive_factor(
            strategy_method, converter_share_method, link, *args)

          demanding_share * loss_compensation_factor *
            converter_share * parent_value
        end
      end

      results.sum
    end
  end

  # Public: Calculates the recursive factor without including losses in the
  # calculations.
  #
  # WARNING: This method should only be used for attributes unrelated to
  # demand. See the exceptions in the code for why.
  #
  # strategy_method        - The method name that controls the flow.
  #
  # converter_share_method - Additional method_name that gives a weight to a
  #                          converter. For example, use #co2_factor to
  #                          exclude converters that have co2 filters.
  #
  # link                   - The link through which we called the
  #                          recursive_factor (this is nil for the first
  #                          converter; recursive_factor uses it internally).
  #
  # *args                  - Additional arguments passed along to the strategy
  #                          method.
  #
  # See +recursive_factor+ for more information.
  #
  # Returns a float.
  def recursive_factor_without_losses(strategy_method, converter_share_method = nil, link = nil, *args)
    if (return_value = send(strategy_method, link, *args)) != nil
      return_value
    else
      val = input_links.map do |link|
        parent = link.rgt_converter

        # Exception 1:
        #
        # When import and local production of a carrier is 0 we still need a
        # share of 1, otherwise the costs for fuel will always be 0.
        #
        # Exception 2:
        #
        # If the demand for a converter is zero, certain links are assigned a
        # nil share. If a slot has two links with nil share, we have to assign
        # shares so they sum up to 1.0 (and not 2.0, if we just did
        # `link.share || 1.0`, to fix exception 1).
        #
        # Therefore we assign averages, just to make this calculation work.
        #
        #                         --(constant: share nil)-- [B] (method: 1.0)
        #                        /
        # slot(conversion: 1.0) <
        #                        \
        #                         --(flexible: share nil)-- [C] (method: 1.0)
        #
        # # (conversion * link_share * value)
        # (1.0 * 1.0 * 1.0) + (1.0 * 1.0 * 1.0)
        # # => 2.0!
        #
        # => This has been changed in Link:
        #      - flexible are assigned share of 1.0 if nil
        #      - constant are assigned share of 0.0 if nil
        #
        link_share = link.share

        if link_share.nil?
          # Following code would make sure that combined link_shares would not
          # be higher than 1.0:
          #
          #   total_link_shares = valid_links.map(&:share).compact.sum
          #   link_share = (1.0 - total_link_shares) / valid_links.length
          link_share = 1.0
        end

        if link_share.zero?
          # If the share is 0.0 there is no point in continuing with the
          # calculation for this link, as any result would be multiplied by
          # zero.
          0.0
        else
          # We have to multiply the share with the conversion of the
          # corresponding slot to deal with following scenario:
          #
          # +---o slot(0.9) <--(1.0)-- [B] (method: 100)
          # | A |
          # +---o slot(0.1) <--(1.0)-- [C] (method: 80)
          #
          # [A] should then be: (0.9 * 1.0 * 100) + (0.1 * 1.0 * 80)
          input = self.input(link.carrier)

          parent_conversion = (input and input.conversion) || 1.0

          # Recurse to the parent...
          parent_value = parent.recursive_factor_without_losses(
            strategy_method, converter_share_method, link, *args)

          link_share * parent_value * parent_conversion
        end
      end

      val.sum
    end
  end

  # Public: Determines if the converter has any parents into which we should
  # recurse when performing calculations.
  #
  # Returns true or false.
  def right_dead_end?
    unless defined?(@right_dead_end)
      @right_dead_end = self.input_links.none? do |link|
        # +! environment?+ is already checked elsewhere.
        ! link.rgt_converter.sector_environment?
      end
    end

    @right_dead_end
  end

  # Public: The loss compensation factor is the amount by which we must
  # multiply the demand of a link in order to account for the losses of the
  # parent (right-hand) converter.
  #
  # A factor of 0.0 means that the converter is 100% loss. A factor of
  # precisely 1.0 indicates the converter has zero loss, while a factor
  # greater than one means that the converter has *some* loss.
  #
  # For example:
  #
  #   loss_output_conversion = 1.0
  #   loss_compensation_factor
  #   # => 0.0
  #
  #   loss_output_conversion = 0.0
  #   loss_compensation_factor
  #   # => 1.0
  #
  #   loss_output_conversion = 0.99
  #   loss_compensation_factor
  #   # => 100.0
  #
  #   loss_output_conversion = 0.2
  #   loss_compensation_factor
  #   # => 1.25
  #
  # Returns a float.
  def loss_compensation_factor
    fetch(:loss_compensation_factor) do
      loss_conversion = loss_output_conversion
      (loss_conversion == 1.0) ? 0.0 : (1.0 / (1.0 - loss_conversion))
    end
  end

  # Public: In contrast to link.share, demanding_share takes also into account
  # losses and zero-demands.
  #
  # For example:
  #
  #   # +--------------+ <--(key:ab_heat share:0.0 carrier:heat)-- +---+
  #   # | A (5 demand) | <--(key:ab_elec share:0.9 carrier:elec)-- | B |
  #   # +--------------+ <--(key:ab_loss share:0.1 carrier:loss)-- +---+
  #
  #   ab_heat.share            # => 0.0
  #   demanding_share(ab_heat) # => 0.0 (edge has no demand [share is 0.0])
  #
  #   ab_elec.share            # => 0.8
  #   demanding_share(ab_elec) # => 0.8
  #
  #   ab_loss.share            # => 0.1
  #   demanding_share(ab_loss) # => 0.0 (carrier is :loss)
  #
  #   # +--------------+                                           +---+
  #   # | X (0 demand) | <--(key:xy_elec share:0.9 carrier:elec)-- | Y |
  #   # +--------------+                                           +---+
  #
  #   xy_elec.share            # => 0.8
  #   demanding_share(xy_elec) # => 0.0 (converter has no share)
  #
  # Returns a float.
  def demanding_share(link)
    return 0.0 if link.loss?

    demanding_share = (link.value || 0.0) / (self.demand || 0.0)

    if demanding_share.nan? || demanding_share.infinite?
      demanding_share = 0.0
    end

    demanding_share
  end

  # Public: Determines the weighting to be assigned to this node when doing
  # recursive_factor calculations.
  #
  # The weighting is determined by calling +method+ on self. If the +method+
  # argument is nil, all converters are assigned an equal weight. Finally,
  # should the method return nil, a weight of zero will be assigned.
  #
  # Returns a float.
  def converter_share(method)
    method.nil? ? 1.0 : (public_send(method) || 0.0)
  end

end # Qernel::RecursiveFactor::Base
