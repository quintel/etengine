# frozen_string_literal: true

module Gql::Runtime
  module Functions
    # Contains GQL functions for retrieving and manipulating curves.
    module Curves
      # Public: Looks up the attachment matching the `name`, and converts the
      # contents into a curve. If no attachment is set, nil is returned.
      def ATTACHED_CURVE(name)
        attachment =
          scope.gql.scenario.scenario_attachments.find_by(attachment_key: name)

        # Not sure if we need this check anymore; this is to check if the name
        # is correct?
        # unless attachment.is_a?(ActiveStorage::Attached)
        #   raise "No such attached file: #{name.inspect}"
        # end

        return nil unless attachment && attachment.custom_curve.attached?

        path = ActiveStorage::Blob.service.path_for(attachment.custom_curve.key)

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
    end
  end
end
