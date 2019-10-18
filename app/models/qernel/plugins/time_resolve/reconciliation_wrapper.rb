# frozen_string_literal: true

module Qernel
  module Plugins
    class TimeResolve
      # A simple wrapper around one or more Reconciliation calculations.
      class ReconciliationWrapper
        def initialize(managers)
          @managers = managers
        end

        def setup
          @managers.each(&:setup_static)
        end

        def inject_values!
          # Calls setup_dynamic and inject on each manager in turn; this allows
          # each manager to refer to curves installed by earlier managers.
          @managers.each do |manager|
            manager.setup_dynamic
            manager.inject_values!
          end
        end
      end
    end
  end
end
