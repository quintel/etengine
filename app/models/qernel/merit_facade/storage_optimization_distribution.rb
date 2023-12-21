# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Distributes the batteries over the sectors that have been turned on for storage optimisation
    class StorageOptimizationDistribution
      OPTIMIZING_SECTORS = %i[households].freeze

      def initialize(adapters, order = [])
        @adapters = adapters
        @order = order
      end

      # Delegate to correct optimizer
      def load_for(key)
        optimizers.each do |opt|
          return opt.load_for(key) if opt.optimizing?(key)
        end
      end

      # Delegate to correct optimizer
      def reserve_for(key)
        optimizers.each do |opt|
          return opt.reserve_for(key) if opt.optimizing?(key)
        end
      end

      private

      def optimizers
        @optimizers ||= optimizing_sectors.map do |sector|
          StorageOptimization.new(
            adapters_for(sector),
            @order,
            optimizing_type: subtype_key_for(sector)
          )
        end
      end

      def adapters_for(sector)
        if sector == :system
          @adapters
        else
          filter_adapters(sector)
        end
      end

      # Private: filters the sector out of the main adapters, returns the sector adapters
      def filter_adapters(sector)
        sector_adapters = []
        @adapters.reject! do |adapter|
          part_of_sector = select_adapter?(sector, adapter)
          sector_adapters << adapter if part_of_sector

          part_of_sector
        end

        sector_adapters
      end

      def select_adapter?(sector, adapter)
        return true if adapter.config.subtype == subtype_key_for(sector)
        return false if adapter.config.type == :flex
        return true if adapter.node.sector_key == sector

        false
      end

      # Private: Check which optimizing storages need to be built
      # Always add system as last sector
      def optimizing_sectors
        OPTIMIZING_SECTORS.select do |sector|
          @adapters.any? { |adapter| adapter.config.subtype == subtype_key_for(sector) }
        end << :system
      end

      def subtype_key_for(sector)
        return :optimizing_storage if sector == :system

        :"optimizing_storage_#{sector}"
      end
    end
  end
end
