# frozen_string_literal: true

module Inspect
  module Scenarios
    class DumpModalComponent < ApplicationComponent
      option :params

      def form_action
        dump_inspect_scenarios_path
      end
    end
  end
end
