module Qernel
  # Provides a slightly different ConverterApi which calculates the full load
  # period as a function of demand, instead of based on the number of units.
  #
  # ConverterApi assumes that, as demand changes, the number of units changes
  # to compensate. But in some cases this is nonsensical; for example, if
  # housing insulation is improved, it makes no sense for the reduced demand
  # to manifest in fewer heating appliances. Instead, it is likely that the
  # same number of appliances will exist, but that they will be used less
  # often.
  class DemandDrivenConverterApi < ConverterApi

    # How many seconds a year the converter runs at full load. Varies
    # depending on the demand.
    def full_load_seconds
      dataset_fetch_handle_nil :full_load_seconds do
        supply = nominal_capacity_heat_output_per_unit * number_of_units
        supply.zero? ? 0.0 : demand / supply
      end
    end

    attributes_required_for :full_load_seconds,
      [ :demand, :nominal_capacity_heat_output_per_unit, :number_of_units ]

    # How many hours a year the converter runs at full load. Varies depending
    # on the demand.
    #
    # Note that dataset_fetch is not used otherwise we end up pulling the
    # (incorrect) value from the dataset, instead of using the dynamic value
    # calculated in full_load_seconds.
    def full_load_hours
      handle_nil(:full_load_hours) { full_load_seconds / 3600 }
    end

    attributes_required_for :full_load_hours, [ :full_load_seconds ]

    # Demand-driven converters have a semi-fixed number of units which changes
    # directly based on user input.
    #
    # In order to determine the number of units, we first find out what share
    # of demand is satisfied in the demanding converter by this converter. For
    # example, if the sum of output share links is 0.2, it is assumed that
    # this converter accounts for 20% of the "technology share".
    #
    # Finally, the number of units is adjusted according to how many
    # households are supplied with heat. For example, if 50% of households are
    # supplied with energy from the converter, but each unit provides energy
    # for 100 homes, the number_of_units will equal 50% of number_households
    # divided by 100.
    #
    def number_of_units
      dataset_fetch_handle_nil :number_of_units do
        heat_links = converter.output_links.select do |link|
          link.carrier && link.carrier.key == :useable_heat
        end

        return 0.0 if heat_links.empty?

        tech_share = sum_unless_empty(heat_links.map(&:share)) || 0
        units = tech_share * (converter.graph.area.number_households || 0)

        units / households_supplied_per_unit
      end
    end

  end # DemandDrivenConverterApi
end # Qernel
