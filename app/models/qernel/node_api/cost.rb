# Supplies the Node API with methods to calculate the yearly costs
# of one plant.
#
# These methods are used in conversion.rb to offer a possibility to convert
# to a number of different units.
module Qernel
  class NodeApi
    # Public: Calculates the input capacity of a typical plant, based on the
    # output capacity in MW.
    #
    # If the node has an electrical efficiency and capacity this is used to
    # calculate the input capacity. Otherwise it checks for a heat capacity and
    # heat efficiency. If this can also not be found it will try cooling.
    #
    # Finally it will try the attribute typical_input_capacity (currently only
    # used for electric transport). If all return nil 0.0 will be used. This
    # should only happen for statistical nodes.
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
    unit_for_calculation 'input_capacity', 'MWinput'

    # Public: Calculates the inital investment costs of a plant.
    #
    # Bbased on the initial investment (purchase costs), installation costs and
    # the additional cost for CCS (if applicable)
    def total_initial_investment
      fetch(:total_initial_investment) do
        initial_investment + ccs_investment + cost_of_installing + storage_costs
      end
    end
    unit_for_calculation 'total_initial_investment', 'euro / plant'

    # Public: The total investment required at the beginning of the project plus
    # the decommissioning costs which have to be paid at the end of the project.
    #
    # Note that decommissioning costs have capital costs associated with them,
    # because it is assumed that the money for this has to be paid up front.
    # This is also the case in the Netherlands.
    #
    # Used to calculate yearly depreciation costs
    def total_investment_over_lifetime
      fetch(:total_investment_over_lifetime) do
        total_initial_investment + decommissioning_costs
      end
    end
    unit_for_calculation 'total_investment_over_lifetime', 'euro / plant'

    # Public: Calculates the marginal costs for a plant in euro per MWh of
    # produced electricity.
    #
    # The marginal costs are the **extra** costs made if an **extra** unit of
    # electricity is produced. It is, in essence, the slope of the cost curve
    # where cost (in euro) is plotted versus total production (in MWh).
    #
    # Returns the marginal costs per MWh (produced electricity)
    def marginal_costs
      fetch(:marginal_costs) do
        variable_costs_per_typical_input(include_waste: false) *
          SECS_PER_HOUR / electricity_output_conversion
      end
    end
    unit_for_calculation 'marginal_costs', 'euro / MWh'

    # Public: Set a marginal cost for the node (in euro /MWh), bypassing
    # the normal marginal cost calculation.
    #
    # Returns the cost.
    def marginal_costs=(value)
      dataset_set(:marginal_costs, value)
    end

    # Public: Calculates the marginal costs for a plant in euro per MWh of
    # produced heat.
    #
    # The marginal costs are the **extra** costs made if an **extra** unit of
    # heat is produced. It is, in essence, the slope of the cost curve where
    # cost (in euro) is plotted versus total production (in MWh).
    #
    # Returns the marginal costs per MWh (produced heat).
    def marginal_heat_costs
      variable_costs_per_typical_input(include_waste: false) *
        SECS_PER_HOUR / heat_output_conversion
    end
    unit_for_calculation 'marginal_heat_costs', 'euro / MWh'

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
    unit_for_calculation 'storage_costs', 'euro / plant'

    private

    # Internal: Calculates the total cost of a plant in euro per plant per year.
    #
    # Total cost is made up of fixed costs and variable costs.
    #
    # Returns the total costs for one plant.
    def total_costs
      fetch(:total_costs) do
        fixed_costs + variable_costs if fixed_costs && variable_costs
      end
    end
    unit_for_calculation 'total_costs', 'euro / plant / year'

    # Internal: Calculates the fixed costs of a node in a given unit.
    #
    # Fixed costs are made up of cost of capital, depreciation costs and fixed
    # operation and maintenance costs.
    #
    # Note that fixed_operation_and_maintenance_costs_per_year is an attribute
    # of the node. There is therefore no method to 'calculate' this for one
    # plant. In conversion.rb there is a method to convert to different other
    # cost units however.
    #
    # Returns the total fixed costs for one plant.
    def fixed_costs
      fetch(:fixed_costs) do
        (cost_of_capital || 0.0) +
          (depreciation_costs || 0.0) +
          (fixed_operation_and_maintenance_costs_per_year || 0.0)
      end
    end
    unit_for_calculation 'fixed_costs', 'euro / plant / year'

    # Internal: Calculates the yearly costs of capital for the unit.
    #
    # Based on the average yearly payment, the weighted average cost of capital
    # (WACC) and a factor to include the construction time in the total rent
    # period of the loan.
    #
    # The ETM assumes that capital has to be held during construction time
    # (and so interest has to be paid during this period) and that technical
    # and economic lifetime are the same.
    #
    # Returns the yearly cost of capital for one plant.
    def cost_of_capital
      fetch(:cost_of_capital) do
        if technical_lifetime.zero?
          raise IllegalZeroError.new(self, :technical_lifetime)
        end

        average_investment * wacc *
          (construction_time + technical_lifetime) / #
          technical_lifetime
      end
    end
    unit_for_calculation 'cost_of_capital', 'euro / plant / year'

    # Internal: Determines the yearly depreciation of the plant over its life.
    #
    # The straight-line depreciation methodology is used.
    #
    # Returns the yearly depreciation costs.
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
    unit_for_calculation 'depreciation_costs', 'euro / plant / year'

    # Internal: Calculates the variable costs for one plant.
    #
    # The variable costs cannot be calculated without knowing how much fuel is
    # consumed by the plant, how much this (mix of) fuel costs etc. The logic is
    # therefore more complex than the fixed costs.
    #
    # Variable costs are made up of fuel costs, co2 emission credit costs
    # and variable operation and mainentance costs
    #
    # Returns the the total variable costs of one plant.
    def variable_costs
      fetch(:variable_costs) do
        typical_input * variable_costs_per_typical_input
      end
    end
    unit_for_calculation 'variable_costs', 'euro / plant / year'

    # Internal Calculates the variable costs per typical input (in MJ).
    #
    # Unlike the variable_costs (defined above), this function does not
    # explicitly depend on the production of the plant.
    #
    # Returns a float.
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
    unit_for_calculation 'variable_costs_per_typical_input', 'euro / MJ'

    # Internal: Calculates the fuel costs for a single plant
    #
    # Based on the input of fuel for one plant and the weighted costs of this /
    # these carrier(s) per mj.
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
    unit_for_calculation 'fuel_costs', 'euro / plant / year'

    # Internal: Determines the costs of co2 emissions.
    #
    # Return the the yearly costs for co2 emissions for one plant.
    def co2_emissions_costs
      fetch(:co2_emissions_costs) do
        typical_input * co2_emissions_costs_per_typical_input
      end
    end
    unit_for_calculation 'co2_emissions_costs', 'euro / plant / year'

    # Internal: Calculates the CO2 emission costs per typical input (in MJ).
    #
    # Unlike co2_emissions_costs, this function does not explicity depend on the
    # production of the plant.
    #
    # DEBT: rename free_co2_factor and takes_part_in_ets
    #
    # Returns a float.
    def co2_emissions_costs_per_typical_input
      fetch(:co2_emissions_costs_per_typical_input) do
        weighted_carrier_co2_per_mj * area.co2_price *
          (1 - area.co2_percentage_free) *
          takes_part_in_ets * ((1 - free_co2_factor))
      end
    end
    unit_for_calculation 'co2_emissions_costs_per_typical_input', 'euro / MJ'

    # Internal: Calculates the variable operation and maintenance costs for one
    # plant.
    #
    # These costs are made up of variable O&M costs for the plant per full load
    # hour and the variable O&M costs for CCS for this plant. Most plants have
    # a variable O&M costs component, but only CCS plants have CCS O&M costs.
    #
    # Returns the yearly variable operation and maintenance costs per plant.
    def variable_operation_and_maintenance_costs
      fetch(:variable_operation_and_maintenance_costs) do
        typical_input *
          variable_operation_and_maintenance_costs_per_typical_input
      end
    end
    unit_for_calculation(
      'variable_operation_and_maintenance_costs',
      'euro / plant / year'
    )

    # Internal: Calculates the variable operation and maintenance costs per
    # typical input (in MJ).
    #
    # Unlike the variable_operation_and_maintenance_costs (defined above), this
    # function does not explicity depend on the production of the plant.
    #
    # Returns the yearly variable operation and maintenance costs per typical
    # input.
    def variable_operation_and_maintenance_costs_per_typical_input
      fetch(:variable_operation_and_maintenance_costs_per_typical_input) do
        return 0.0 if input_capacity.zero?

        (variable_operation_and_maintenance_costs_per_full_load_hour +
          variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour) /
          (input_capacity * 3600.0)
      end
    end
    unit_for_calculation(
      'variable_operation_and_maintenance_costs_per_typical_input',
      'euro / MJ'
    )

    # Internal: The average yearly installment of capital cost repayments,
    # assuming a linear repayment scheme. That is why divided by 2, to be at
    # 50% between initial cost and 0.
    #
    # Returns a float.
    def average_investment
      fetch(:average_investment) { total_investment_over_lifetime / 2 }
    end
    unit_for_calculation 'average_investment', 'euro / plant / year'

    # Internal: This method calculates the input capacity of a plant based on
    # the electrical output capacity and electrical efficiency of the node.
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
    unit_for_calculation 'electric_based_input_capacity', 'MWinput'

    # Internal: Calculates the input capacity of a plant based on the heat
    # output capacity and heat efficiency of the node.
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
    unit_for_calculation 'heat_based_input_capacity', 'MWinput'

    # Internal: Calculates the input capacity of one plant based on the heat
    # capacity of the plant and the cooling efficiency.
    #
    # The ETM does not have seperate cooling capacity, so use heat capacity to
    # calculate cooling based nominal input capacity. This method will only
    # be called with cooling technologies which have no heat output.
    #
    # DEBT: move to another file when cleaning up Node API
    #
    # Returns the input capacity of a plant based on the output capacity and the
    # cooling efficiency of the plant
    def cooling_based_input_capacity
      fetch(:cooling_based_input_capacity) do
        if cooling_output_conversion && cooling_output_conversion > 0
          heat_output_capacity / cooling_output_conversion
        end
      end
    end
    unit_for_calculation 'cooling_based_input_capacity', 'MWinput'

    # Internal: Calculates the typical electricity output of one plant of this
    # type.
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
    unit_for_calculation 'typical_electricity_output', 'MJ / year'

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
    unit_for_calculation 'typical_heat_output', 'MJ / year'

    # Internal: Calculates the typical fuel input of one plant of this type.
    #
    # Used for variable costs: fuel costs and CO2 emissions costs
    #
    # DEBT: move to another file when cleaning up Node API
    #
    # Returns the typical fuel input of one plant in MJ.
    def typical_input
      fetch(:typical_input) { input_capacity * full_load_seconds }
    end
    unit_for_calculation 'typical_input', 'MJ / year'

    # Internal: Determines the share of output energy which is accounted for
    # when calculating fuel and CO2 costs.
    #
    # Some nodes split input energy into multiple carriers, but one or more of
    # those is considered a "waste product" and should not be considered when
    # calculating costs. For example, a gas CHP may take in gas as an input and
    # outputs electricity, steam hot water, and loss, but only electricity and
    # part of the loss are costable byproducts of the conversion, while the heat
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
    unit_for_calculation 'costable_energy_factor', 'factor'

    # The conversions used by costable_energy_factor to determine how to
    # calculate fuel and CO2 costs based on the output carriers.
    #
    # Returns an array containing the costable conversion, loss conversion, and
    # total of all outputs. Returns an empty array if the node does not have any
    # waste_outputs configured.
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
  end
end
