# frozen_string_literal: true

module Qernel
  module Causality
    # Creates a demand profile for the reconciliation carrier by reading a curve
    # from the node.
    module SelfDemandProfile
      # Raised when the profile name is invalid and does not refer to a valid
      # attribute containing a curve.
      class NoSuchCurveAttribute < RuntimeError
        def initialize(attribute, node)
          @attribute = attribute
          @node_key = node.key
        end

        def message
          <<~MESSAGE.squish
            No such curve attribute #{@attribute.inspect}; was specified by
            node #{@node_key} to create a profile for
            #{profile_name.inspect}
          MESSAGE
        end

        private

        def profile_name
          "self: #{@attribute}".strip
        end
      end

      # Raised when the node does not have a curve value.
      class MissingCurve < NoSuchCurveAttribute
        def message
          <<~MESSAGE.squish
            Node #{@node_key} does not have a #{@attribute.inspect} to
            use as profile #{profile_name.inspect}
          MESSAGE
        end
      end

      # Regex which should match curve names, extracting the carrier and
      # direction.
      CURVE_RE =
        /\A(?<carrier>[\w_]+)_(?<direction>input|output)_curve\Z/.freeze

      # Public: Given a curve name, decodes the carrier name and direction.
      #
      # Returns a hash with :carrier and :direction keys or nil if the curve
      # name is not valid.
      def self.decode_name(name)
        name = name.to_s

        if (colon_idx = name.index(':'))
          name = name[(colon_idx + 1)..-1].strip
        end

        match = name.match(CURVE_RE)

        return nil unless match

        match.named_captures.symbolize_keys!.transform_values!(&:to_sym)
      end

      # Public: Fetches a demand profile from a node.
      #
      # node - The Qernel::NodeApi
      # attribute - The name of the attribute which contains the carrier curve.
      #
      # Returns an Array.
      def self.curve(node, attribute)
        attribute = attribute.to_s.strip

        unless attribute.to_s.match?(CURVE_RE) &&
            node.respond_to?(attribute)
          raise NoSuchCurveAttribute.new(attribute, node)
        end

        curve = node.public_send(attribute)

        raise MissingCurve.new(attribute, node) if curve.blank?

        curve
      end

      # Public: Creates a demand profile for a node based on an existing carrier
      # input or output curve.
      #
      # node - The Qernel::NodeApi
      # attribute - The name of the attribute which contains the carrier curve.
      #
      # For example:
      #
      #   SelfDemandProfile.profile(node, 'electricity_input_curve')
      #   # => Creates the demand curve for `node` based on the value of
      #   #    the `electricity_input_curve` attribute.
      #
      # Returns an Array.
      def self.profile(node, attribute)
        curve = curve(node, attribute)
        sum = curve.sum

        return curve if sum.zero?

        total = sum * 3600 # MJ to MWh
        curve.map { |val| val / total }
      end
    end
  end
end
