# frozen_string_literal: true

module Api
  module V3
    # Sends useful responses when users access removed features.
    class RemovedFeaturesController < BaseController
      # GET   /api/v3/scenarios/:id/flexibility_order
      # PATCH /api/v3/scenarios/:id/flexibility_order
      # PUT   /api/v3/scenarios/:id/flexibility_order
      def flexibility_order
        render_not_found({ error: <<-MSG.squish })
          The flexibility order feature has been removed. Flexible technologies are now sorted
          implicitly by their marginal cost / willingness to pay.
        MSG
      end
    end
  end
end
