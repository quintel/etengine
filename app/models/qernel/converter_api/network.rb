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

  # Public: Calculates how much additional network capacity is required to meet
  # the peak load.
  #
  # See etmodel#1961
  # See etengine#803
  #
  # Returns a float.
  def required_additional_network_capacity_in_mw(peak_load)
    if dataset_get(:capacity_distribution).blank?
      fail "Cannot calculate `required_additional_network_capacity_in_mw' on " \
           "#{ key } as it doesn't define a `capacity_distribution'"
    end

    begin
      distribution = Atlas::Dataset.find(graph.area.area_code)
        .capacity_distribution(dataset_get(:capacity_distribution))
    rescue Errno::ENOENT
      # Some regions do not have all the necessary capacity distribution CSV
      # files.
      return 0.0
    end

    capacity_per = (
      network_capacity_available_in_mw +
      network_capacity_used_in_mw
    ) / distribution.length

    peak_load_per = peak_load.to_f / distribution.length

    distribution.sum do |dist|
      additional = peak_load_per - capacity_per * dist
      additional < 0 ? 0.0 : additional
    end
  end

  unit_for_calculation 'required_additional_network_capacity_in_mw', 'MW'

end
