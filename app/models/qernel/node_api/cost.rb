# frozen_string_literal: true

module Qernel
  module NodeApi
    # Supplies the Node API with methods to calculate the yearly costs of one plant.
    #
    # These methods are used in conversion.rb to offer a possibility to convert to a number of
    # different units.
    module Cost
      # Public: Calculates the input capacity of a typical plant, based on the  output capacity in
      # MW.
      #
      # If the node has a "typical_input_capacity" defined, this value is always used. When no
      # typical input capacity is defined (in the node document), the input capacity will be
      # calculated based on the electricity, heat, or cooling inputs.
      #
      # Return a float of the input capacity of a typical plant in MWinput
      def input_capacity
        fetch(:input_capacity) do
          typical_input_capacity ||
            electric_based_input_capacity ||
            heat_based_input_capacity ||
            cooling_based_input_capacity ||
            0.0
        end
      end

      # Public: Calculates the inital investment costs of a plant.
      #
      # Based on the initial investment (purchase costs), installation costs and the additional cost
      # for CCS (if applicable)
      #
      # Returns a numeric value representing cost per plant.
      def total_initial_investment
        fetch(:total_initial_investment) do
          if initial_investment.nil? && ccs_investment.nil? && cost_of_installing.nil? &&
              storage_costs&.zero? && capacity_costs&.zero?
            nil
          else
            (initial_investment || 0.0) +
              (ccs_investment || 0.0) +
              (cost_of_installing || 0.0) +
              (storage_costs || 0.0) +
              (capacity_costs || 0.0)
          end
        end
      end

      # Public: The total investment required at the beginning of the project plus the
      # decommissioning costs which have to be paid at the end of the project.
      #
      # Note that decommissioning costs have capital costs associated with them, because it is
      # assumed that the money for this has to be paid up front.
      #
      # Used to calculate yearly depreciation costs
      #
      # Returns a numeric value representing cost per plant.
      def total_investment_over_lifetime
        fetch(:total_investment_over_lifetime) do
          total_initial_investment + decommissioning_costs
        end
      end

      # Public: Calculates the marginal costs for a plant in euro per MWh of produced electricity.
      #
      # The marginal costs are the extra costs made if one unit of electricity is produced. It is,
      # in essence, the slope of the cost curve where cost (in euro) is plotted versus total
      # production (in MWh).
      #
      # Returns the marginal costs per MWh (produced electricity)
      def marginal_costs
        fetch(:marginal_costs, false) do
          if output(:electricity).nil?
            nil
          elsif electricity_output_conversion.zero?
            0.0
          else
            variable_costs_per_typical_input(include_waste: false) *
              SECS_PER_HOUR / # Highlighting
              electricity_output_conversion
          end
        end
      end

      # Public: Set a marginal cost for the node (in euro /MWh), bypassing the normal marginal cost
      # calculation.
      #
      # Returns the cost.
      def marginal_costs=(value)
        dataset_set(:marginal_costs, value)
      end

      # Public: Returns the maximum price the node is willing to pay for energy.
      #
      # This is used only by flexibility technologies which participate in the electricity merit
      # order. A value may be defined in the ETSource data for the node, or by the user with an
      # input. If neither, this defaults to returning the node's marginal costs.
      #
      # Returns the price per MWh.
      def max_consumption_price
        dataset_get(:max_consumption_price) || marginal_costs
      end

      # Public: Sets the maximum allowed price at which a flex technology will consume energy.
      #
      # Returns the price.
      def max_consumption_price=(new_price)
        dataset_set(:max_consumption_price, new_price)
      end

      # Public: Sets an array to be used as a marginal cost curve.
      #
      # This only applies for certain merit order participants. If the given curve is empty, nil is
      # set instead.
      #
      # Returns the curve.
      def marginal_cost_curve=(curve)
        # Ignore empty curves and set no value.
        dataset_set(:marginal_cost_curve, curve&.any? ? curve : nil)
      end

      # Public: Calculates the marginal costs for a plant in euro per MWh of produced heat.
      #
      # The marginal costs are the extra costs made if one unit of heat is produced. It is, in
      # essence, the slope of the cost curve where cost (in euro) is plotted versus total production
      # (in MWh).
      #
      # Returns the marginal costs per MWh (produced heat).
      def marginal_heat_costs
        variable_costs_per_typical_input(include_waste: false) *
          SECS_PER_HOUR / heat_output_conversion
      end

      # Public: Calculates the cost of storage attached to the node.
      #
      # Returns the total cost of storage for one plant.
      def storage_costs
        fetch(:storage_costs) do
          if (storage = dataset_get(:storage))
            (storage.volume || 0.0) * (storage.cost_per_mwh || 0.0)
          else
            0.0
          end
        end
      end

      # Public: Calculates a fixed price for the input capacity of the node.
      #
      # This is rarely used, but features in some types of storage which have a cost associated with
      # the total installed input capacity.
      def capacity_costs
        fetch(:capacity_costs) do
          if fixed_costs_per_mw_input_capacity
            fixed_costs_per_mw_input_capacity * input_capacity
          else
            0.0
          end
        end
      end

      # Public: Calculates the total CAPEX (operating expenses) for the node
      #
      # Capital expenditures (CAPEX) are major investments that are designed to be
      # used over the long term. The yearly costs for these investments are based on
      # the WACC and plant lifetime. If the plant does not have CCS installed, these
      # costs are zero.
      #

      def capital_expenditures
        fetch(:capital_expenditures) do
          (cost_of_capital || 0.0) +
            (depreciation_costs || 0.0)
        end
      end

      # Public: Calculates the CAPEX (capital expenditures) for CCS for the node
      #
      # Returns the yearly capital expenditure for CCS in euro.
      def capital_expenditures_ccs
        fetch(:capital_expenditures_ccs) do
          (cost_of_capital_ccs || 0.0) +
            (depreciation_costs_ccs || 0.0)
        end
      end

      # Public: Calculates the CAPEX (capital expenditures) excluding CCS for the node
      #
      # Capital expenditures (CAPEX) are major investments that are designed to be
      # used over the long term. The yearly costs for these investments are based on
      # the WACC and plant lifetime.
      #
      # Returns the yearly capital expenditure excluding CCS in euro.
      def capital_expenditures_excluding_ccs
        fetch(:capital_expenditures_excluding_ccs) do
          (capital_expenditures) -
            (capital_expenditures_ccs)
        end
      end

      # Public: Calculates the total OPEX (operating expenses) for the node
      #
      # Operating expenses for CCS include varaible O&M costs and CO2 emissions costs.

      def operating_expenses
        fetch(:operating_expenses) do
          variable_operation_and_maintenance_costs +
          fixed_operation_and_maintenance_costs_per_year +
          co2_emissions_costs

        end
      end

      # Public: Calculates the OPEX (operating expenses) for CCS for the node
      #
      # Returns the yearly operating expenses for CCS in euro.
      def operating_expenses_ccs
        fetch(:operating_expenses_ccs) do
          variable_operation_and_maintenance_costs_for_ccs + co2_emissions_costs
        end
      end

      # Public: Calculates the OPEX (operating expenses) excluding CCS for the node.
      #
      # Operating expenses inculde variable O&M costs and fixed O&M costs, without CCS.
      #
      # Returns the yearly operating expenses excluding CCS in euro.
      def operating_expenses_excluding_ccs
        fetch(:operating_expenses_excluding_ccs) do
          variable_operation_and_maintenance_costs -
            variable_operation_and_maintenance_costs_for_ccs +
            fixed_operation_and_maintenance_costs_per_year
        end
      end

      private

      # Internal: Calculates the total cost of a plant in euro per plant per year.
      #
      # Total cost is made up of fixed costs and variable costs.
      #
      # Returns the total costs for one plant per year.
      def total_costs
        fetch(:total_costs) do
          fixed_costs + variable_costs if fixed_costs && variable_costs
        end
      end

      # Internal: Calculates the fixed costs of a node in a given unit.
      #
      # Fixed costs are made up of cost of capital, depreciation costs and fixed operation and
      # maintenance costs.
      #
      # Note that fixed_operation_and_maintenance_costs_per_year is an attribute of the node. There
      # is therefore no method to 'calculate' this for one plant. In conversion.rb there is a method
      # to convert to different other cost units however.
      #
      # Returns the total fixed costs for one plant per year.
      def fixed_costs
        fetch(:fixed_costs) do
          (cost_of_capital || 0.0) +
            (depreciation_costs || 0.0) +
            (fixed_operation_and_maintenance_costs_per_year || 0.0)
        end
      end

      # Internal: Calculates the yearly costs of capital for the unit.
      #
      # Based on the average yearly payment, the weighted average cost of capital (WACC) and a
      # factor to include the construction time in the total rent period of the loan.
      #
      # The ETM assumes that capital has to be held during construction time (and so interest has to
      # be paid during this period) and that technical and economic lifetime are the same.
      #
      # Returns the yearly cost of capital for one plant per year.
      def cost_of_capital
        fetch(:cost_of_capital) do
          if technical_lifetime.zero?
            raise IllegalZeroError.new(self, :technical_lifetime)
          end

          average_investment * wacc *
            (construction_time + technical_lifetime) / # syntax
            technical_lifetime
        end
      end


      ### Retuns the yearly cost of capital for the CCS part of one plant per year
      def cost_of_capital_ccs
        fetch(:cost_of_capital_ccs) do
          if technical_lifetime.zero?
            raise IllegalZeroError.new(self, :technical_lifetime)
          end

          average_investment_ccs * wacc *
            (construction_time + technical_lifetime) / # syntax
            technical_lifetime
        end
      end



      # Internal: Determines the yearly depreciation of the plant over its life.
      #
      # The straight-line depreciation methodology is used.
      #
      # Returns the yearly depreciation costs per plant per year.
      def depreciation_costs
        fetch(:depreciation_costs) do
          if technical_lifetime.zero?
            raise IllegalZeroError.new(self, :technical_lifetime)
          end

          investment = total_investment_over_lifetime

          if investment && investment < 0
            raise IllegalNegativeError.new(
              self, :total_investment_over_lifetime, investment
            )
          end

          investment / technical_lifetime
        end
      end


      ## Returns the yearly depreciation costs for the CCS part of one plant per yar

      def depreciation_costs_ccs
        fetch(:depreciation_costs) do
          if technical_lifetime.zero?
            raise IllegalZeroError.new(self, :technical_lifetime)
          end

          investment = ccs_investment

          if investment && investment < 0
            raise IllegalNegativeError.new(
              self, :total_investment_over_lifetime, investment
            )
          end

          ccs_investment / technical_lifetime
        end
      end

      # Internal: Calculates the variable costs for one plant.
      #
      # The variable costs cannot be calculated without knowing how much fuel is consumed by the
      # plant, how much this (mix of) fuel costs etc. The logic is therefore more complex than the
      # fixed costs.
      #
      # Variable costs are made up of fuel costs, co2 emission credit costs and variable operation
      # and mainentance costs
      #
      # Returns the the total variable costs of one plant per year.
      def variable_costs
        fetch(:variable_costs) do
          typical_input * variable_costs_per_typical_input
        end
      end

      # Internal Calculates the variable costs per typical input (in MJ).
      #
      # Unlike the variable_costs (defined above), this function does not explicitly depend on the
      # production of the plant.
      #
      # Returns a float representing cost per MJ.
      def variable_costs_per_typical_input(include_waste: true)
        cache_key =
          if include_waste
            :variable_costs_per_typical_input
          else
            :variable_costs_per_typical_input_except_waste
          end

        fetch(cache_key) do
          costable =
            weighted_carrier_cost_per_mj +
            co2_emissions_costs_per_typical_input

          costable *= costable_energy_factor unless include_waste

          costable + variable_operation_and_maintenance_costs_per_typical_input
        end
      end

      # Internal: Calculates the fuel costs for a single plant
      #
      # Based on the input of fuel for one plant and the weighted costs of this / these carrier(s)
      # per mj.
      #
      # Returns the the yearly fuel costs for one single plant.
      def fuel_costs
        fetch(:fuel_costs) do
          if typical_input && typical_input < 0
            raise IllegalNegativeError.new(self, :typical_input, typical_input)
          end

          typical_input * weighted_carrier_cost_per_mj
        end
      end

      # Internal: Determines the costs of co2 emissions.
      #
      # Return the the yearly costs for co2 emissions for one plant.
      def co2_emissions_costs
        fetch(:co2_emissions_costs) do
          typical_input * co2_emissions_costs_per_typical_input
        end
      end

      # Internal: Calculates the CO2 emission costs per typical input (in MJ).
      #
      # Unlike co2_emissions_costs, this function does not explicity depend on the production of the
      # plant.
      #
      # DEBT: rename free_co2_factor and takes_part_in_ets
      #
      # Returns a float representing cost per MJ.
      def co2_emissions_costs_per_typical_input
        fetch(:co2_emissions_costs_per_typical_input) do
          weighted_carrier_co2_per_mj * area.co2_price *
            (1 - area.co2_percentage_free) *
            (takes_part_in_ets || 1.0) * ((1 - free_co2_factor))
        end
      end

      # Internal: Calculates the variable operation and maintenance costs for one plant.
      #
      # These costs are made up of variable O&M costs for the plant per full load hour and the
      # variable O&M costs for CCS for this plant. Most plants have a variable O&M costs component,
      # but only CCS plants have CCS O&M costs.
      #
      # Returns the yearly variable operation and maintenance costs per plant.
      def variable_operation_and_maintenance_costs
        fetch(:variable_operation_and_maintenance_costs) do
          typical_input *
            variable_operation_and_maintenance_costs_per_typical_input
        end
      end

      # Internal: Calculates the variable operation and maintenance costs for CCS for one plant.
      #
      # Only CCS plants have O&M costs for CCS.
      #
      # Returns the yearly variable operation and maintenance costs for CCS per plant.
      def variable_operation_and_maintenance_costs_for_ccs
        fetch(:variable_operation_and_maintenance_costs_for_ccs) do
          return 0.0 if input_capacity.zero?

          typical_input *
            variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour /
            (input_capacity * 3600.0)
        end
      end

      # Internal: Calculates the variable operation and maintenance costs per typical input (in MJ).
      #
      # Unlike the variable_operation_and_maintenance_costs (defined above), this function does not
      # explicity depend on the production of the plant.
      #
      # Returns the yearly variable operation and maintenance costs per MJ input.
      def variable_operation_and_maintenance_costs_per_typical_input
        fetch(:variable_operation_and_maintenance_costs_per_typical_input) do
          return 0.0 if input_capacity.zero?

          (variable_operation_and_maintenance_costs_per_full_load_hour +
            variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour) / # highlighting
            (input_capacity * 3600.0)
        end
      end

      # Internal: The average yearly installment of capital cost repayments, assuming a linear
      # repayment scheme. That is why divided by 2, to be at 50% between initial cost and 0.
      #
      # Returns a float representing cost per plant per year.
      def average_investment
        fetch(:average_investment) { total_investment_over_lifetime / 2 }
      end


      # Returns a float representing cost of the ccs part of one plant per year.
      def average_investment_ccs
        fetch(:average_investment_ccs) { (ccs_investment || 0.0) / 2 }
      end

      # Internal: This method calculates the input capacity of a plant based on the electrical
      # output capacity and electrical efficiency of the node.
      #
      # DEBT: move to another file when cleaning up Node API.
      #
      # Returns the typical input capacity of a plant in MWinput.
      def electric_based_input_capacity
        fetch(:electric_based_input_capacity) do
          if electricity_output_conversion && electricity_output_conversion > 0
            electricity_output_capacity / electricity_output_conversion
          end
        end
      end

      # Internal: Calculates the input capacity of a plant based on the heat output capacity and
      # heat efficiency of the node.
      #
      # DEBT: move to another file when cleaning up Node API.
      #
      # Returns the typical input capacity of a plant in MWinput.
      def heat_based_input_capacity
        fetch(:heat_based_input_capacity) do
          if heat_output_conversion && heat_output_conversion > 0
            heat_output_capacity / heat_output_conversion
          end
        end
      end

      # Internal: Calculates the input capacity of one plant based on the heat capacity of the plant
      # and the cooling efficiency.
      #
      # The ETM does not have seperate cooling capacity, so use heat capacity to calculate cooling
      # based nominal input capacity. This method will only be called with cooling technologies
      # which have no heat output.
      #
      # DEBT: move to another file when cleaning up Node API
      #
      # Returns the input capacity of a plant based on the output capacity and the cooling
      # efficiency of the plant
      def cooling_based_input_capacity
        fetch(:cooling_based_input_capacity) do
          if cooling_output_conversion && cooling_output_conversion > 0
            heat_output_capacity / cooling_output_conversion
          end
        end
      end

      # Internal: Calculates the typical electricity output of one plant of this type.
      #
      # Used for conversion of plant to other units
      #
      # DEBT: move to another file when cleaning up Node API
      #
      # Returns the typical electricity output in MJ.
      def typical_electricity_output
        fetch(:typical_electricity_output) do
          typical_input * electricity_output_conversion
        end
      end

      # Internal: Calculates the typical heat output of one plant of this type.
      #
      # Used for conversion of plant to other units
      #
      # DEBT: move to another file when cleaning up Node API
      #
      # Returns the typical heat output in MJ.
      def typical_heat_output
        fetch(:typical_heat_output) do
          typical_input * heat_and_cold_output_conversion
        end
      end

      # Internal: Calculates the typical fuel input of one plant of this type.
      #
      # Used for variable costs: fuel costs and CO2 emissions costs
      #
      # DEBT: move to another file when cleaning up Node API
      #
      # Returns the typical fuel input of one plant in MJ.
      def typical_input
        fetch(:typical_input) { input_capacity * capacity_to_demand_multiplier * full_load_hours }
      end

      # Internal: Determines the share of output energy which is accounted for when calculating fuel
      # and CO2 costs.
      #
      # Some nodes split input energy into multiple carriers, but one or more of those is considered
      # a "waste product" and should not be considered when calculating costs. For example, a gas
      # CHP may take in gas as an input and outputs electricity, steam hot water, and loss, but only
      # electricity and part of the loss are costable byproducts of the conversion, while the heat
      # is a "free" waste product.
      #
      # Returns a numeric.
      def costable_energy_factor
        fetch(:costable_energy_factor) do
          costable, loss, total = costable_conversions

          if costable.nil?
            1.0
          elsif (total - loss).positive?
            costable + loss * costable / (total - loss)
          else
            0.0
          end
        end
      end

      # The conversions used by costable_energy_factor to determine how to calculate fuel and CO2
      # costs based on the output carriers.
      #
      # Returns an array containing the costable conversion, loss conversion, and total of all
      # outputs. Returns an empty array if the node does not have any waste_outputs configured.
      def costable_conversions
        return [] unless node.waste_outputs&.any?

        loss = 0.0
        costable = 0.0
        total = 0.0

        node.outputs.each do |output|
          if output.loss?
            loss = output.conversion
          elsif !node.waste_outputs.include?(output.carrier.key)
            costable += output.conversion
          end

          total += output.conversion
        end

        [costable, loss, total]
      end

      # Internal: Calculates the yearly factor needed to calculate the CAPEX (capital expenditure)
      # of the node.
      #
      # Defines what part of the initial capital investments will be spent on a yearly basis
      #
      # Returns a factor that can be multiplied with an investment
      def expenditure_factor_per_lifetime_year
        raise IllegalZeroError.new(self, :technical_lifetime) if technical_lifetime.zero?

        (wacc + 1) / (technical_lifetime + construction_time)
      end
    end
  end
end
