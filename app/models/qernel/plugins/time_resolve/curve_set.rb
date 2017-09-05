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
        set_dir = dataset.dataset_dir.join('curves').join(name)

        unless set_dir.directory?
          raise Errno::ENOENT, "No curve-set \"#{ name }\" at #{ set_dir }"
        end

        variant_dir = set_dir.join(variant.to_s)
        variant_dir = set_dir.join('default') unless variant_dir.directory?

        new(variant_dir)
      end

      private_class_method :new

      def initialize(dir)
        @dir = Pathname.new(dir)
      end

      # Public: The named curve as a Merit::LoadProfile.
      #
      # TODO: A LoadProfile is too specific; a Curve or plain array would be
      # preferred.
      #
      # Returns a Merit::LoadProfile.
      def curve(name)
        ::Merit::LoadProfile.load(@dir.join("#{ name }.csv"))
      end
    end # CurveSet
  end
end
