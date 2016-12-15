module Qernel::Plugins
  # Based on the configuration of the Area, disables sectors of the graph by
  # setting the demand of all converters - and constant links - to zero.
  class DisableSectors
    include Plugin

    before :first_calculation, :disable_sectors

    def self.enabled?(graph)
      graph.area.disabled_sectors.any?
    end

    def disable_sectors
      disabled = @graph.area.disabled_sectors

      @graph.converters.each do |converter|
        next unless disabled.include?(converter.sector_key)

        if converter.dataset_get(:number_of_units)
          converter.dataset_set(:number_of_units, 0.0)
        end

        if converter.sector_key != :energy || converter.preset_demand
          converter.demand = converter.preset_demand = 0.0
        end

        converter.input_links.each do |link|
          link.share = 0.0 if link.link_type == :constant
        end
      end
    end
  end # DisableSectors
end # Qernel::Plugins
