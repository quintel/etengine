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
        if disabled.include?(converter.sector_key)
          converter.demand          = 0.0
          converter.preset_demand   = 0.0

          converter.input_links.each do |link|
            link.share = 0.0 if link.link_type == :constant
          end
        end
      end
    end
  end # DisableSectors
end # Qernel::Plugins
