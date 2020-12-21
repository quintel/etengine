# frozen_string_literal: true

module Gql::Runtime
  module Functions
    # Contains GQL functions for retrieving and manipulating curves.
    module Curves
      # Public: Looks up the attachment matching the `name`, and converts the
      # contents into a curve. If no attachment is set, nil is returned.
      def ATTACHED_CURVE(name)
        name = name.to_s

        # Use to_a.find to take advantage of the eager-loaded attachments and blobs.
        attachment = scope.gql.scenario.attachments.to_a.find { |a| a.key == name }

        return nil unless attachment&.file&.attached?

        path = ActiveStorage::Blob.service.path_for(attachment.file.key)

        # The graph wants an array. Loading a curve and converting to an array
        # is expensive since Merit::Curve has to deal with the possibility of
        # missing/default values. Using the reader directly avoids this
        # overhead.
        Merit::Curve.reader.read(path)
      end

      # Public: If the given `curve` is an array of non-zero length, it is
      # returned. If the curve is nil or empty, a new curve of `length` length
      # is created, with each value set to `default`.
      def COALESCE_CURVE(curve, default = 0.0, length = 8760)
        curve&.any? ? curve : [default] * length
      end

      # Public: Creates a new curve where each index (n) is the sum of (0..n) in the source curve.
      #
      # Returns an array.
      def CUMULATIVE_CURVE(curve)
        output = Array.new(curve.length)
        running_total = 0.0

        curve.each.with_index do |val, index|
          output[index] = (running_total += val)
        end

        output
      end
    end
  end
end
