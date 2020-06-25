# frozen_string_literal: true

module Qernel
  module NodeApi
    # Attributes relating to employment.
    module Employment
      extend ActiveSupport::Concern

      ATTRIBUTES = %i[
        hours_prep_nl
        hours_prep_abroad
        hours_prod_nl
        hours_prod_abroad
        hours_place_nl
        hours_place_abroad
        hours_maint_nl
        hours_maint_abroad
        hours_remov_nl
        hours_remov_abroad
      ].freeze

      included do
        dataset_accessors(*ATTRIBUTES)
      end
    end
  end
end
