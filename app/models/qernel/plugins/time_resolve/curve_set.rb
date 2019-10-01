module Qernel::Plugins
  class TimeResolve
    class CurveSet
      # Public: Creates a new CurveSet containing profiles from the given
      # dataset.
      #
      # dataset - An Atlas::Dataset in which the profile set can be found.
      # subpath - Path to the subdirectory containing all the profile sets of
      #           the same type.
      # variant - The particular variant of the profile set to load.
      #
      # For example
      #
      #   # Loads the "cold_snap" variant of the "heat" in the NL region. These
      #   # files will be in: etsource/datasets/nl/curves/heat/cold_snap.
      #   CurveSet.with_dataset(
      #     Atlas::Dataset.find(:nl),
      #     'heat',
      #     'cold_snap'
      #   )
      #
      # Returns a CurveSet. If the CurveSet does not exist, falls back to the
      # "default" variant.
      def self.with_dataset(dataset, name, variant)
        unless dataset.curve_sets.curve_set?(name)
          raise Errno::ENOENT,
            "No curve-set \"#{name}\" for dataset #{dataset.key}"
        end

        set = dataset.curve_sets.curve_set(name)
        set.variant(variant) || set.variant('default')
      end
    end # CurveSet
  end
end
