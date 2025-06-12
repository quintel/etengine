# frozen_string_literal: true

class Inspect::Scenarios::LoadModalComponent < ApplicationComponent
  option :params

  def form_action
    load_dump_inspect_scenarios_path
  end
end
