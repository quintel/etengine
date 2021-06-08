module Qernel::RecursiveFactor::Base

  # Public: Recursively traverses the graph from "self" (this node) to
  # the parent (supplier) nodes. It does so by following its input_edges
  # according to a +strategy method+. The strategy method returns either:
  #
  #   * a 'weight' of a edge/path. When returning a weight, the
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
  # node_share_method - Additional method_name that gives a weight to a
  #                          node. For example, use #co2_factor to
  #                          exclude nodes that have co2 filters.
  #
  # edge                   - The edge through which we called the
  #                          recursive_factor (this is nil for the first
  #                          node; recursive_factor uses it internally).
  #
  # *args                  - Additional arguments passed along to the strategy
  #                          method.
  #
  # Returns a float.
  def recursive_factor(
    strategy_method,
    node_share_method = nil,
    edge = nil,
    *args,
    include_abroad: false
  )
    if (!include_abroad && abroad?) || recursive_factor_ignore?
      0.0
    elsif (return_value = send(strategy_method, edge, *args)) != nil
      return_value
    else
      results = input_edges.map do |edge|
        parent = edge.rgt_node.query

        # The demanding_share returns the right-to-left share. This is the
        # same as +edge.share+ except when the carrier is loss, in which case
        # the share will always be 0.0 since we include losses separately
        # using +loss_compensation_factor+.
        #
        # [A] <-- [B] (demanding_share = 100%)
        #      \- [C] (demanding_share = 100%)
        #
        # [A] needs to be 100% * [B] + 100% * [C]
        demanding_share = demanding_share(edge)

        # The output of the parent needs to be multiplied by this
        # "compensation factor" to include losses.
        #
        # See https://github.com/quintel/etengine/issues/518.
        parent_output_compensation_factor = parent.query.output_compensation_factor

        # What part is considered to be contributing to the outcome?
        # (e.g. 80% when free_co2_factor is 20%). This is 100% when the
        # node_share method is nil.
        node_share = node_share(node_share_method)

        if demanding_share.zero?
          # The node has no demand, we can safely omit it.
          0.0
        elsif parent_output_compensation_factor.zero?
          # The node is 100% loss, so there is no point in recursing
          # further on this edge.
          0.0
        elsif node_share.zero?
          # The node has been assigned a weight of zero, so we can safely
          # omit it.
          0.0
        else
          parent_value = parent.recursive_factor(
            strategy_method, node_share_method, edge, *args,
            include_abroad: include_abroad
          )

          demanding_share * parent_output_compensation_factor *
            node_share * parent_value
        end
      end

      results.sum
    end
  end

  # Public: Calculates the recursive factor without including losses in the
  # calculations.
  #
  # WARNING: This method should only be used for attributes unrelated to demand.
  #
  # strategy_method   - The method name that controls the flow.
  # node_share_method - Additional method_name that gives a weight to a node. For example, use
  #                     `co2_factor` to exclude nodes that have co2 filters.
  # edge              - The edge through which we called the recursive_factor (this is nil for the
  #                     first node; recursive_factor uses it internally).
  # type:             - See "value types".
  # *args             - Additional arguments passed along to the strategy method.
  #
  # See `recursive_factor` for more information.
  #
  # ### Value types
  #
  # `recursive_factor_without_losses` is typically used to calculate a factor describing the shares
  # and conversions for a path between the current node and a terminal node on the right of the
  # graph. These factors are then multiplied by a value from the current node to get a final value.
  #
  # When instead you intend to read a value from the terminal node, propagating that value back
  # towards the the current node, `type` should be set to `:value` so that input shares can be
  # compensated for. This is because input efficiencies would otherwise influence the propagated
  # value:
  #
  #     +----------+ - - - - - +      + - - - - - +----------+
  #     | Consumer | gas @ 0.6 |  <-  | gas @ 1.0 | Producer |
  #     +----------+ - - - - - +      + - - - - - +----------+
  #
  # If the producer has a `sustainability_share` of 0.5, then so should the consumer, since the
  # producer is the sole supplier of energy. However, if `type` is _not_ set to `:value` and instead
  # remains as `:factor`, the producer sustainability share will be multiplied by 0.6, resulting in
  # the wrong recursive value on the consumer of 0.5 * 0.6 = 0.3.
  #
  # Returns a float.
  def recursive_factor_without_losses(
    strategy_method,
    node_share_method = nil,
    edge = nil,
    *args,
    include_abroad: false,
    value_type: :factor
  )
    if (!include_abroad && abroad?) || recursive_factor_ignore?
      0.0
    elsif (return_value = send(strategy_method, edge, *args)) != nil
      return_value
    else
      val = input_edges.map do |edge|
        parent = edge.rgt_node.query

        # Exception 1:
        #
        # When import and local production of a carrier is 0 we still need a
        # share of 1, otherwise the costs for fuel will always be 0.
        #
        # Exception 2:
        #
        # If the demand for a node is zero, certain edges are assigned a
        # nil share. If a slot has two edges with nil share, we have to assign
        # shares so they sum up to 1.0 (and not 2.0, if we just did
        # `edge.share || 1.0`, to fix exception 1).
        #
        # Therefore we assign averages, just to make this calculation work.
        #
        #                         --(constant: share nil)-- [B] (method: 1.0)
        #                        /
        # slot(conversion: 1.0) <
        #                        \
        #                         --(flexible: share nil)-- [C] (method: 1.0)
        #
        # # (conversion * edge_share * value)
        # (1.0 * 1.0 * 1.0) + (1.0 * 1.0 * 1.0)
        # # => 2.0!
        #
        # => This has been changed in Edge:
        #      - flexible are assigned share of 1.0 if nil
        #      - constant are assigned share of 0.0 if nil
        #
        edge_share = edge.share

        if edge_share.nil?
          # Following code would make sure that combined edge_shares would not
          # be higher than 1.0:
          #
          #   total_edge_shares = valid_edges.map(&:share).compact.sum
          #   edge_share = (1.0 - total_edge_shares) / valid_edges.length
          edge_share = 1.0
        end

        if edge_share.zero?
          # If the share is 0.0 there is no point in continuing with the
          # calculation for this edge, as any result would be multiplied by
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
          input = self.input(edge.carrier)

          parent_conversion = input&.conversion || 1.0

          # Recurse to the parent...
          parent_value = parent.recursive_factor_without_losses(
            strategy_method, node_share_method, edge, *args,
            include_abroad: include_abroad,
            value_type: value_type
          )

          edge_share * parent_value * parent_conversion *
            (value_type == :value ? input_compensation_factor : 1.0)
        end
      end

      val.sum
    end
  end

  # Public: Determines if the node has any parents into which we should
  # recurse when performing calculations.
  #
  # Returns true or false.
  def right_dead_end?
    unless defined?(@right_dead_end)
      @right_dead_end = self.input_edges.none? do |edge|
        # +! environment?+ is already checked elsewhere.
        ! edge.rgt_node.sector_environment?
      end
    end

    @right_dead_end
  end

  # Public: Determines if the node has any parents into which we should
  # recurse when performing calculations. A domestic dead end includes when the
  # node inputs are all abroad.
  #
  # Returns true or false.
  def domestic_dead_end?
    unless defined?(@domestic_dead_end)
      @domestic_dead_end = right_dead_end? ||
        input_edges.all? { |edge| edge.rgt_node.abroad? }
    end

    @domestic_dead_end
  end

  # Public: A combination of output and loss output compensation factors.
  #
  # Allows the adjustment of recursivelly calculated values for loss outputs, and nodes where the
  # sum of outputs exceed 1.
  #
  # This is used in `recursive_factor`, but not `recursive_factor_without_losses`.
  #
  # ### Why compensate for losses?
  #
  # When a supplier node has 200 demand, gives 100 to a consumer and loses 100, we need to
  # compensate for this loss. When calculating the primary demand on the consumer node, we want to
  # know how much energy was needed on the supplier to provide 100 to the consumer. Losses are
  # therefore _included_ in the resulting value: the supplier has 200 primary demand.
  #
  # See Base#loss_compensation_factor
  # See Base#output_efficiency_compensation_factor
  def output_compensation_factor
    fetch(:output_compensation_factor) do
      loss_compensation_factor * output_efficiency_compensation_factor
    end
  end

  # Public: The loss compensation factor is the amount by which we must multiply the demand of a
  # edge in order to account for the losses of the parent (right-hand) node.
  #
  # A factor of 0.0 means that the node is 100% loss. A factor of precisely 1.0 indicates the node
  # has zero loss, while a factor greater than one means that the node has *some* loss.
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
    loss_conversion = loss_output_conversion
    loss_conversion == 1.0 ? 0.0 : (1.0 / (1.0 - loss_conversion))
  end

  # Internal: Factor which compensates for output efficiencies greater than zero.
  #
  # When the sum of non-loss outputs exceed 1.0, more energy leaves the node than enters. This is
  # typically the result of conversions being used to model output efficiency. In these situations
  # recursive_factor will return values which are too high.
  #
  # For example, imagine a supplier which outputs 60% of its input as electricity, and 60% as heat.
  #
  #                 [Supplier = 100]
  #                     /      \
  #      [Electricity = 60]  [Heat = 60]
  #
  # The primary demand of the electricity node is 50: 50 energy is needed on the supplier to produce
  # 60 electricity.
  #
  # The output efficiency compensation factor is a value which may be used in recursive factor
  # calculations to fix this error. In this example, the factor will be 0.833... the number which
  # 60 must be multiplied by to get the correct value of 50.
  #
  # When the sum of non-loss outputs is less than one, no compensation is needed and this method
  # always returns 1.0.
  #
  # Returns a numeric.
  def output_efficiency_compensation_factor
    factor = outputs.sum { |output| output.loss? ? 0.0 : output.conversion }
    factor > 1 ? 1.0 / factor : 1.0
  end

  # Internal: Used only by `recursive_factor_without_losses` when propagating values, this ensures
  # that value are preserved even when the node has inputs which don't sum to 1.0.
  #
  # See "Value types" for `recursive_factor_without_losses`.
  #
  # Returns a numeric.
  def input_compensation_factor
    1.0 / inputs.sum(&:conversion)
  end

  # Public: The parent share of the edge.
  #
  # Always returns 0.0 when the edge represents loss (preventing further recursion) or if the share
  # is incalculable.
  #
  # Returns a float.
  def demanding_share(edge)
    return 0.0 if edge.loss?

    demanding_share = (edge.demand || 0.0) / (demand || 0.0)
    demanding_share.nan? || demanding_share.infinite? ? 0.0 : demanding_share
  end

  # Public: Determines the weighting to be assigned to this node when doing
  # recursive_factor calculations.
  #
  # The weighting is determined by calling +method+ on self. If the +method+
  # argument is nil, all nodes are assigned an equal weight. Finally,
  # should the method return nil, a weight of zero will be assigned.
  #
  # Returns a float.
  def node_share(method)
    method.nil? ? 1.0 : (public_send(method) || 0.0)
  end
end
