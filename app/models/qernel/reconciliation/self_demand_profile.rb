# frozen_string_literal: true

module Qernel
  module Reconciliation
    # Creates a demand profile for the reconciliation carrier by reading a curve
    # from the node.
    module SelfDemandProfile
      # Raised when the profile name is invalid and does not refer to a valid
      # attribute containing a curve.
      class NoSuchCurveAttribute < RuntimeError
        def initialize(attribute, converter)
          @attribute = attribute
          @converter_key = converter.key
        end

        def message
          <<~MESSAGE.squish
            No such curve attribute #{@attribute.inspect}; was specified by
            converter #{@converter_key} to create a profile for
            #{profile_name.inspect}
          MESSAGE
        end

        private

        def profile_name
          "self: #{@attribute}".strip
        end
      end

      # Raised when the converter does not have a curve value.
      class MissingCurve < NoSuchCurveAttribute
        def message
          <<~MESSAGE.squish
            Converter #{@converter_key} does not have a #{@attribute.inspect} to
            use as profile #{profile_name.inspect}
          MESSAGE
        end
      end

      # Regex which should match curve names, extracting the carrier and
      # direction.
      CURVE_RE = /\A\w+_(?:input|output)_curve\Z/.freeze

      # Public: Creates a demand curve for a node based on an existing carrier
      # input or output curve.
      #
      # converter - The Qernel::Converter
      # attribute - The name of the attribute which contains the carrier curve.
      #
      # For example:
      #
      #   SelfDemandProfile.create(converter, 'electricity_input_curve')
      #   # => Creates the demand curve for `converter` based on the value of
      #   #    the `electricity_input_curve` attribute.
      #
      # Returns an Array.
      def self.build(converter, attribute)
        attribute = attribute.to_s.strip

        unless attribute.to_s.match?(CURVE_RE) &&
            converter.query.respond_to?(attribute)
          raise NoSuchCurveAttribute.new(attribute, converter)
        end

        curve = converter.query.public_send(attribute)

        raise MissingCurve.new(attribute, converter) if curve.blank?

        total = curve.sum * 3600 # MJ to MWh
        curve.map { |val| val / total }
      end
    end
  end
end