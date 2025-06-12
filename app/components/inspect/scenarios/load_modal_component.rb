# frozen_string_literal: true

module Inspect
  module Scenarios
    class LoadModalComponent < ApplicationComponent
      option :params

      def form_action
        load_dump_inspect_scenarios_path
      end
    end
  end
end
