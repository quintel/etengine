# frozen_string_literal: true

module Qernel
  module Causality
    # Contains helpers for reading CurveSet data.
    module CurveSet
      # Public: Creates a new CurveSet containing profiles from the given
      # dataset.
      #
      # area    - A Qernel::Area for which the curves should be loaded.
      # name    - Name of the curve set to load.
      # variant - Optional name of the variant to load. If not provided, the
      #           name will be determined automatically using
      #           `selected_variant_name`.
      #
      # For example
      #
      #   # Loads the "cold_snap" variant of the "heat" in the NL region. These
      #   # files will be in: etsource/datasets/nl/curves/heat/cold_snap.
      #   CurveSet.for_area(area, 'heat', 'cold_snap')
      #
      # Returns an Atlas::Dataset::CurveSet::Variant.
      def self.for_area(area, name, variant = nil)
        dataset = Atlas::Dataset.find(area.area_code)

        unless dataset.curve_sets.key?(name)
          raise Errno::ENOENT,
            "No curve-set \"#{name}\" for dataset #{dataset.key}"
        end

        variant_name = variant || CurveSet.selected_variant_name(area, name)

        set = dataset.curve_sets.get(name)
        set.variant(variant_name) || set.variant('default')
      end

      # Public: Given an area, determines the name of the variant to be loaded
      # for the named curve set.
      #
      # area - A Qernel::Area.
      # name - The name of the curve set.
      #
      # Returns a String.
      def self.selected_variant_name(area, name)
        area.public_send("#{name}_curve_set")
      rescue NoMethodError
        'default'
      end
    end
  end
end
