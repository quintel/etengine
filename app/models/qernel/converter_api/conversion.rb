class Qernel::ConverterApi

  # For the following methods we want to have a method that
  # returns the cost per unit.
  #
  # Example:
  #   total_costs_per(:converter)
  #   => 129721.8
  #
  %w[
    total_costs
    fixed_costs
    cost_of_capital
    depreciation_costs
    variable_costs
    fuel_costs
    co2_emissions_costs
    variable_operations_and_maintenance_costs
  ].each do |method_name|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{ method_name }_per(unit)
        convert_to( #{ method_name }, unit )
      end
    RUBY
  end

  #######
  private
  #######

  # This methods converts the cost of one (typical sized) 'plant'
  # to another unit.
  #
  # Example:
  #   convert_to(1000, :mw_input)
  #   => 1272.16
  #
  # Of course, you can use the outcome of another method here:
  #
  # Example:
  #   convert_to(total_costs, :mw_input)
  #   => 12972.12
  #
  def convert_to(cost, unit)
    case

    # Plant and Converter
    when unit == :plant
      cost
    when unit == :converter
      cost * real_number_of_units

    # MW
    when unit == :mw_input
      cost / effective_input_capacity
    when unit == :mw_electricity
      cost / output_capacity_electricity
    when unit == :mw_heat
      cost / output_capacity_heat

    # MWh
    when unit == :mwh_input
      cost / demand / SECS_PER_HOUR / real_number_of_units
    when unit == :mwh_electricity
      cost / output_of_electricity / SECS_PER_HOUR / real_number_of_units
    when unit == :mwh_heat
      cost / output_of_heat_carriers / SECS_PER_HOUR / real_number_of_units

    # Some other unit that is unknown
    else
      raise ArgumentError, "#{unit} unknown! Cannot convert."
    end
  end

end
