class Qernel::ConverterApi

  def delta_in_capacity_in_mw
    fetch(:delta_in_capacity_in_mw) do
      (number_of_units - peak_load_units_present) * electricity_output_capacity
    end
  end
  unit_for_calculation "delta_in_capacity_in_mw", 'MW'

  def peak_load_in_mw
    fetch(:peak_load_in_mw) do
      (electricity_output_conversion + electricity_input_conversion) *
        input_capacity * number_of_units
    end
  end
  unit_for_calculation "peak_load_in_mw", 'MW'

end
