# frozen_string_literal: true

class Inspect::Scenarios::DumpModalComponent < ApplicationComponent
  option :params

  def form_action
    dump_inspect_scenarios_path
  end
end
