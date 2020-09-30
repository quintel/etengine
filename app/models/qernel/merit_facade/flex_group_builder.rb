# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Constructs Merit::Flex::Groups.
    module FlexGroupBuilder
      # Public: Takes an ETSource config for a flexibility group, and creates
      # a Merit::Flex::Group to be used in the calculation.
      def self.build(key, config)
        sorting =
          case config['order']
          when 'asc'  then Merit::Sorting.by_sortable_cost
          when 'desc' then Merit::Sorting.by_sortable_cost_desc
          else             Merit::Sorting::Unsorted.new
          end

        group_class =
          if config['behavior'] == 'share'
            Merit::Flex::ShareGroup
          elsif key == 'export'
            Merit::Flex::CostBasedShareGroup
          else
            Merit::Flex::Group
          end

        group_class.new(key.to_sym, sorting)
      end
    end
  end
end
